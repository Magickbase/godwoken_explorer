defmodule GodwokenExplorer.Account do
  use GodwokenExplorer, :schema

  import Ecto.Changeset
  import GodwokenRPC.Util, only: [script_to_hash: 1, hex_to_number: 1]

  require Logger

  alias GodwokenRPC
  alias GodwokenExplorer.Chain.Events.Publisher
  alias GodwokenIndexer.Account.Worker, as: AccountWorker

  @primary_key {:id, :integer, autogenerate: false}
  schema "accounts" do
    field :ckb_address, :binary
    field :ckb_lock_script, :map
    field :ckb_lock_hash, :binary
    field :eth_address, :binary
    field :script_hash, :binary
    field :short_address, :binary
    field :script, :map
    field :nonce, :integer

    field :type, Ecto.Enum,
      values: [:meta_contract, :udt, :user, :polyjuice_root, :polyjuice_contract]

    field :layer2_tx, :binary
    has_many :account_udts, GodwokenExplorer.AccountUDT

    timestamps()
  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [
      :id,
      :ckb_address,
      :ckb_lock_script,
      :ckb_lock_hash,
      :eth_address,
      :script_hash,
      :script,
      :nonce,
      :type,
      :layer2_tx,
      :short_address
    ])
    |> validate_required([:id, :script_hash])
  end

  def create_or_update_account(attrs) do
    case Repo.get(__MODULE__, attrs[:id]) do
      nil -> %__MODULE__{}
      account -> account
    end
    |> changeset(attrs)
    |> Repo.insert_or_update()
    |> case do
      {:ok, account} ->
        account_api_data = account.id |> find_by_id() |> account_to_view()
        Publisher.broadcast([{:accounts, account_api_data}], :realtime)
        {:ok, account}

      {:error, error_msg} ->
        Logger.error(fn -> ["Failed to create or update account: ", error_msg] end)
        {:error, nil}
    end
  end

  def count() do
    from(
      a in Account,
      select: fragment("COUNT(*)")
    )
    |> Repo.one(timeout: :infinity)
  end

  def update_meta_contract(global_state) do
    with meta_contract when not is_nil(meta_contract) <- Repo.get(Account, 0) do
      atom_script =
        for {key, val} <- meta_contract.script, into: %{}, do: {String.to_atom(key), val}

      new_script = atom_script |> Map.merge(global_state)

      case meta_contract
           |> Ecto.Changeset.change(script: new_script)
           |> Repo.update() do
        {:ok, account} ->
          account_api_data = 0 |> find_by_id() |> account_to_view()
          Publisher.broadcast([{:accounts, account_api_data}], :realtime)
          {:ok, account}

        {:error, schema} ->
          {:error, schema}
      end
    end
  end

  def find_by_id(id) do
    account = Repo.get(Account, id)
    ckb_udt_id = UDT.ckb_account_id()

    ckb_balance =
      with udt_id when is_integer(udt_id) <- ckb_udt_id do
        case Repo.get_by(AccountUDT, %{account_id: id, udt_id: udt_id}) do
          %AccountUDT{balance: balance} -> balance
          nil -> Decimal.new(0)
        end
      else
        nil -> Decimal.new(0)
      end

    eth_balance =
      with udt_id when is_integer(udt_id) <- UDT.eth_account_id() do
        case Repo.get_by(AccountUDT, %{account_id: id, udt_id: udt_id}) do
          %AccountUDT{balance: balance} -> balance
          nil -> Decimal.new(0)
        end
      else
        nil -> Decimal.new(0)
      end

    tx_count = Transaction.list_by_account_id(id) |> Repo.aggregate(:count)

    base_map = %{
      id: id,
      type: account.type,
      ckb: ckb_balance |> Decimal.to_string(),
      eth: eth_balance |> Decimal.to_string(),
      tx_count: tx_count |> Integer.to_string()
    }

    case account do
      %Account{type: :meta_contract} ->
        %{
          meta_contract: %{
            account_merkle_state: account.script["account_merkle_state"],
            block_merkle_state: account.script["block_merkle_state"],
            reverted_block_root: account.script["reverted_block_root"],
            last_finalized_block_number: account.script["last_finalized_block_number"],
            status: account.script["status"]
          }
        }

      %Account{type: :user} ->
        udt_list = AccountUDT.list_udt_by_account_id(id)

        %{
          user: %{
            eth_addr: account.eth_address,
            nonce: account.nonce |> Integer.to_string(),
            ckb_lock_script: account.ckb_lock_script,
            udt_list: udt_list
          }
        }

      %Account{type: :polyjuice_root} ->
        %{
          polyjuice: %{
            script: account.script,
            script_hash: account.script_hash
          }
        }

      %Account{type: :polyjuice_contract} ->
        %{
          smart_contract: %{
            # create account's tx_hash needs godwoken api support
            tx_hash: "",
            eth_addr: account.short_address
          }
        }

      %Account{type: :udt, id: ^ckb_udt_id} ->
        udt = Repo.get(UDT, id)
        holders = UDT.count_holder(id)

        %{
          sudt: %{
            name: udt.name || "Unkown##{id}",
            symbol: udt.symbol,
            decimal: (udt.decimal || 8) |> Integer.to_string(),
            supply: (udt.supply || Decimal.new(0)) |> Decimal.to_string(),
            holders: (holders || 0) |> Integer.to_string(),
            script_hash: account.script_hash
          }
        }

      %Account{type: :udt, id: id} ->
        udt = Repo.get(UDT, id)
        holders = UDT.count_holder(id)

        %{
          sudt: %{
            name: udt.name || "Unkown##{id}",
            symbol: udt.symbol,
            decimal: (udt.decimal || 8) |> Integer.to_string(),
            supply: (udt.supply || Decimal.new(0)) |> Decimal.to_string(),
            holders: (holders || 0) |> Integer.to_string(),
            type_script: udt.type_script,
            script_hash: account.script_hash
          }
        }
    end
    |> Map.merge(base_map)
  end

  def account_to_view(account) do
    account =
      Map.merge(account, %{
        ckb: balance_to_view(account.ckb, 8),
        eth: balance_to_view(account.eth, 18)
      })

    case Kernel.get_in(account, [:user, :udt_list]) do
      udt_list when not is_nil(udt_list) ->
        Kernel.put_in(
          account,
          [:user, :udt_list],
          udt_list
          |> Enum.map(fn udt ->
            %{udt | balance: balance_to_view(udt.balance, udt.decimal)}
          end)
        )

      _ ->
        account
    end
  end

  defp balance_to_view(balance, decimal) do
    {val, _} = Integer.parse(balance)
    (val / :math.pow(10, decimal)) |> :erlang.float_to_binary(decimals: decimal)
  rescue
    _ ->
      balance
  end

  def refetch_accounts(account_ids) do
    ckb_udt_id = UDT.ckb_account_id()
    AccountWorker.trigger_account(account_ids)
    AccountWorker.trigger_sudt_account([{ckb_udt_id, account_ids}])
  end

  def search(keyword) do
    results =
      from(a in Account,
        where:
          a.eth_address == ^keyword or a.ckb_lock_hash == ^keyword or a.script_hash == ^keyword or
            a.short_address == ^keyword,
        order_by: a.id
      )
      |> Repo.all()

    if length(results) > 1 do
      refetch_accounts(results |> Enum.map(fn account -> account.id end))
      nil
    else
      results |> List.first()
    end
  end

  def bind_ckb_lock_script(l1_lock_script, script_hash, l1_lock_hash) do
    case GodwokenRPC.fetch_account_id(script_hash) do
      nil ->
        Logger.error("Fetch user account error:#{script_hash}")
        Process.sleep(2000)
        bind_ckb_lock_script(l1_lock_script, script_hash, l1_lock_hash)
      hex_account_id ->
        account_id = hex_to_number(hex_account_id)
        short_address = String.slice(script_hash, 0, 42)

        if from(a in Account, where: a.script_hash == ^script_hash and a.id != ^account_id) |> Repo.exists? do
          exist_accounts_ids = from(a in Account, select: a.id, where: a.script_hash == ^script_hash and a.id != ^account_id) |> Repo.all()
          Logger.info("script_hash same but id not same#{Enum.join(exist_accounts_ids, ",")}")
          refetch_accounts(exist_accounts_ids)
        end

        if from(a in Account, where: a.script_hash != ^script_hash and a.id == ^account_id) |> Repo.exists? do
          from(a in Account, where: a.script_hash != ^script_hash and a.id == ^account_id)
          |> Repo.all()
          |> Enum.each(fn account ->
            Logger.info("script_hash is not same but id same#{account.id}")

            spawn(Account, :bind_ckb_lock_script, [account.ckb_lock_script, account.script_hash, account.ckb_lock_hash])
          end)
        end

        if from(a in Account, where: a.script_hash == ^script_hash and a.id == ^account_id) |> Repo.exists? do
          Logger.info("already exist account")
          {:ok, Repo.get(Account, account_id)}
          # deposit history
        else
          create_or_update_account(%{
            id: account_id,
            ckb_lock_script: l1_lock_script,
            ckb_lock_hash: l1_lock_hash,
            script_hash: script_hash,
            short_address: short_address,
            type: "user"
          })
        end
    end
  end

  def create_udt_account(udt_script, udt_script_hash) do
    if udt_script_hash == "0x0000000000000000000000000000000000000000000000000000000000000000" do
      ckb_udt_id = UDT.ckb_account_id()

      {:ok, ckb_udt_id}
    else
      udt_code_hash = Application.get_env(:godwoken_explorer, :udt_code_hash)
      rollup_script_hash = Application.get_env(:godwoken_explorer, :rollup_script_hash)

      account_script = %{
        "code_hash" => udt_code_hash,
        "hash_type" => "type",
        "args" => rollup_script_hash <> String.slice(udt_script_hash, 2..-1)
      }

      l2_udt_script_hash = script_to_hash(account_script)
      short_address = String.slice(l2_udt_script_hash, 0, 42)

      case Repo.get_by(Account, script_hash: l2_udt_script_hash) do
        nil ->
          case GodwokenRPC.fetch_account_id(l2_udt_script_hash) do
            nil ->
              Logger.error("Fetch udt account id failed: #{l2_udt_script_hash}")
              {:error, nil}

            hex_account_id when is_binary(hex_account_id) ->
              udt_account_id = hex_to_number(hex_account_id)

              {:ok, _udt} =
                UDT.find_or_create_by(%{
                  id: udt_account_id,
                  script_hash: udt_script_hash,
                  type_script: udt_script
                })

              __MODULE__.create_or_update_account(%{
                id: udt_account_id,
                script: account_script,
                script_hash: l2_udt_script_hash,
                short_address: short_address,
                type: "udt"
              })

              {:ok, udt_account_id}
          end

        %__MODULE__{id: udt_account_id} ->
          {:ok, udt_account_id}
      end
    end
  end

  def find_by_short_address(short_address) do
    case Repo.get_by(__MODULE__, %{short_address: short_address}) do
      %__MODULE__{id: id} ->
        {:ok, id}

      nil ->
        script_hash = GodwokenRPC.fetch_script_hash(%{short_address: short_address})
        account_id = script_hash |> GodwokenRPC.fetch_account_id() |> hex_to_number()
        {:ok, account_id}
    end
  end
end
