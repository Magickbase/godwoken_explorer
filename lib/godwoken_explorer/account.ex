defmodule GodwokenExplorer.Account do
  use GodwokenExplorer, :schema

  import Ecto.Changeset
  import GodwokenRPC.Util, only: [script_to_hash: 1, hex_to_number: 1]

  require Logger

  alias GodwokenRPC
  alias GodwokenExplorer.Chain.Events.Publisher

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

    ckb_balance =
      case Repo.get_by(AccountUDT, %{account_id: id, udt_id: 1}) do
        %AccountUDT{balance: balance} -> balance
        nil -> Decimal.new(0)
      end

    tx_count = Transaction.list_by_account_id(id) |> Repo.aggregate(:count)

    base_map = %{
      id: id,
      type: account.type,
      ckb: ckb_balance |> Decimal.to_string(),
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
            script: account.script
          }
        }

      %Account{type: :polyjuice_contract} ->
        %{
          smart_contract: %{
            tx_hash: "0x3bd26903a0c8c418d1fba9be7eb13d088b8e68dc1f1d34941c8916246532cccf"
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
            type_script: udt.type_script
          }
        }
    end
    |> Map.merge(base_map)
  end

  def account_to_view(account) do
    account = %{account | ckb: balance_to_view(account.ckb, 8)}

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

  def search(keyword) do
    from(a in Account,
      where: a.eth_address == ^keyword or a.ckb_lock_hash == ^keyword or a.script_hash == ^keyword
    )
    |> Repo.one()
  end

  def bind_ckb_lock_script(l1_lock_script, script_hash, l1_lock_hash) do
    account = Repo.get_by(Account, script_hash: script_hash)
    short_address = String.slice(script_hash, 0, 42)

    case account do
      nil ->
        case GodwokenRPC.fetch_account_id(script_hash) do
          nil ->
            {:error, nil}

          hex_account_id ->
            account_id = hex_to_number(hex_account_id)

            create_or_update_account(%{
              id: account_id,
              ckb_lock_script: l1_lock_script,
              ckb_lock_hash: l1_lock_hash,
              script_hash: script_hash,
              short_address: short_address,
              type: "user"
            })
        end

      %Account{ckb_lock_script: ckb_lock_script, ckb_lock_hash: ckb_lock_hash}
      when is_nil(ckb_lock_script) or is_nil(ckb_lock_hash) ->
        account
        |> Ecto.Changeset.change(%{ckb_lock_script: l1_lock_script, ckb_lock_hash: l1_lock_hash})
        |> Repo.update()

      _ ->
        {:ok, account}
    end
  end

  def create_udt_account(udt_script, udt_script_hash) do
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

  def get_eth_address_or_id(id) do
    case Repo.get(Account, id) do
      %__MODULE__{eth_address: eth_address} when is_binary(eth_address) ->
        eth_address

      _ ->
        id
    end
  end
end
