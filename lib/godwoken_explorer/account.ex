defmodule GodwokenExplorer.Account do
  use GodwokenExplorer, :schema

  import GodwokenRPC.Util, only: [script_to_hash: 1, balance_to_view: 2]

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
    has_many :account_udts, AccountUDT
    has_one :smart_contract, SmartContract

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

  def create_or_update_account!(attrs) do
    case Repo.get_by(__MODULE__, script_hash: attrs[:script_hash]) do
      nil -> %__MODULE__{}
      account -> account
    end
    |> changeset(attrs)
    |> Repo.insert_or_update!()
    |> case do
      account = %Account{} ->
        account_api_data = account.id |> find_by_id() |> account_to_view()
        Publisher.broadcast([{:accounts, account_api_data}], :realtime)
        {:ok, account}

      {:error, error_msg} ->
        Logger.error("Failed to create or update account: #{inspect(error_msg)}")
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
      with udt_id when is_integer(udt_id) <- UDT.ckb_account_id(),
           {:ok, balance} <- GodwokenRPC.fetch_balance(account.short_address, udt_id) do
        balance
      else
        _ -> ""
      end

    eth_balance =
      with udt_id when is_integer(udt_id) <- UDT.eth_account_id(),
           {:ok, balance} <- GodwokenRPC.fetch_balance(account.short_address, udt_id) do
        balance
      else
        _ -> ""
      end

    tx_count = GodwokenExplorer.Chain.Cache.AccountTransactionCount.get(account.id)

    base_map = %{
      id: id,
      type: account.type,
      ckb: ckb_balance,
      eth: eth_balance,
      tx_count: tx_count |> Integer.to_string(),
      eth_addr: elem(display_id(id), 0)
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
        udt_list = AccountUDT.fetch_realtime_udt_blance(id)

        %{
          user: %{
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
            # create account's tx_hash needs godwoken api support
            tx_hash: ""
          }
        }

      %Account{type: :udt, id: id} ->
        udt = Repo.get(UDT, id)
        if is_nil(udt) do
          %{
            sudt: %{
              name: "Unkown##{id}"
            }
          }
        else
          holders = UDT.count_holder(id)
          type_script =
            if id == UDT.ckb_account_id do
              nil
            else
              udt.type_script
            end

          %{
            sudt: %{
              name: udt.name || "Unkown##{id}",
              symbol: udt.symbol,
              icon: udt.icon,
              decimal: udt.decimal,
              supply: (udt.supply || Decimal.new(0)) |> Decimal.to_string(:normal),
              holders: holders || 0,
              type_script: type_script,
              script_hash: account.script_hash
            }
          }
        end
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
            %{udt | balance: balance_to_view(udt.balance, udt.decimal || 8)}
          end)
        )

      _ ->
        account
    end
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
      Logger.error("Same keyword Error: #{keyword}")
      nil
    else
      results |> List.first()
    end
  end

  def find_or_create_udt_account!(
        udt_script,
        udt_script_hash,
        l1_block_number \\ 0,
        tip_block_number \\ 0
      ) do
    case Repo.get_by(UDT, script_hash: udt_script_hash) do
      %UDT{id: id} ->
        {:ok, id}

      nil ->
        udt_code_hash = Application.get_env(:godwoken_explorer, :udt_code_hash)
        rollup_script_hash = Application.get_env(:godwoken_explorer, :rollup_script_hash)

        account_script = %{
          "code_hash" => udt_code_hash,
          "hash_type" => "type",
          "args" => rollup_script_hash <> String.slice(udt_script_hash, 2..-1)
        }

        l2_udt_script_hash = script_to_hash(account_script)
        short_address = String.slice(l2_udt_script_hash, 0, 42)

        case GodwokenRPC.fetch_account_id(l2_udt_script_hash) do
          {:error, :account_slow} ->
            if l1_block_number + 100 > tip_block_number do
              raise "account may not created now at #{l1_block_number}"
            end

          {:error, nil} ->
            {:error, nil}

          {:ok, udt_account_id} ->
            {:ok, _udt} =
              UDT.find_or_create_by(%{
                id: udt_account_id,
                script_hash: udt_script_hash,
                type_script: udt_script
              })

            __MODULE__.create_or_update_account!(%{
              id: udt_account_id,
              script: account_script,
              script_hash: l2_udt_script_hash,
              short_address: short_address,
              type: "udt"
            })

            {:ok, udt_account_id}
        end
    end
  end

  def find_by_short_address(short_address) do
    case Repo.get_by(__MODULE__, %{short_address: short_address}) do
      %__MODULE__{id: id} ->
        {:ok, id}

      nil ->
        {:ok, script_hash} = GodwokenRPC.fetch_script_hash(%{short_address: short_address})
        account_id = script_hash |> GodwokenRPC.fetch_account_id() |> elem(1)
        {:ok, account_id}
    end
  end

  def switch_account_type(code_hash, args) do
    polyjuice_code_hash = Application.get_env(:godwoken_explorer, :polyjuice_validator_code_hash)
    layer2_lock_code_hash = Application.get_env(:godwoken_explorer, :layer2_lock_code_hash)
    udt_code_hash = Application.get_env(:godwoken_explorer, :udt_code_hash)
    meta_contract_code_hash = Application.get_env(:godwoken_explorer, :meta_contract_code_hash)
    eoa_code_hash = Application.get_env(:godwoken_explorer, :eoa_code_hash)

    case code_hash do
      ^meta_contract_code_hash -> :meta_contract
      ^udt_code_hash -> :udt
      ^polyjuice_code_hash when byte_size(args) == 74 -> :polyjuice_root
      ^polyjuice_code_hash -> :polyjuice_contract
      ^layer2_lock_code_hash -> :user
      ^eoa_code_hash -> :user
      _ -> :unkonw
    end
  end

  def script_to_eth_adress(type, args) do
    rollup_script_hash = Application.get_env(:godwoken_explorer, :rollup_script_hash)

    if type in [:user, :polyjuice_contract] &&
         args |> String.slice(0, 66) == rollup_script_hash do
      "0x" <> String.slice(args, -40, 40)
    else
      nil
    end
  end

  def add_name_to_polyjuice_script(type, script) do
    if type in [:polyjuice_contract, :polyjuice_root] do
      script |> Map.merge(%{"name" => "validator"})
    else
      script
    end
  end

  def display_id(id) do
    case from(a in Account,
           left_join: s in SmartContract,
           on: s.account_id == a.id,
           where: a.id == ^id,
           select: %{
             type: a.type,
             eth_address: a.eth_address,
             short_address: a.short_address,
             contract_name: s.name
           }
         )
         |> Repo.one() do
      %{
        type: type,
        eth_address: eth_address,
        short_address: short_address,
        contract_name: contract_name
      } ->
        cond do
          type == :user -> {eth_address, eth_address}
          type in [:udt, :polyjuice_contract] -> {short_address, contract_name || short_address}
          type == :polyjuice_root -> {short_address, "Deploy Contract"}
          type == :meta_contract -> {short_address, "Meta Contract"}
          true -> {id, id}
        end

      nil ->
        {:ok, script_hash} = GodwokenRPC.fetch_script_hash(%{account_id: id})
        script = GodwokenRPC.fetch_script(script_hash)
        type = switch_account_type(script["code_hash"], script["args"])

        cond do
          type == :user ->
            {Account.script_to_eth_adress(type, script["args"]),
             Account.script_to_eth_adress(type, script["args"])}

          type == :polyjuice_contract ->
            {script_hash |> String.slice(0, 42), script_hash |> String.slice(0, 42)}

          type == :polyjuice_root ->
            {script_hash |> String.slice(0, 42), "Deploy Contract"}

          true ->
            {id, id}
        end
    end
  end

  def manual_create_account(id) do
    nonce = GodwokenRPC.fetch_nonce(id)
    {:ok, script_hash} = GodwokenRPC.fetch_script_hash(%{account_id: id})
    short_address = String.slice(script_hash, 0, 42)
    script = GodwokenRPC.fetch_script(script_hash)
    type = switch_account_type(script["code_hash"], script["args"])
    eth_address = script_to_eth_adress(type, script["args"])
    parsed_script = add_name_to_polyjuice_script(type, script)
    attrs = %{
      id: id,
      script: parsed_script,
      script_hash: script_hash,
      short_address: short_address,
      type: type,
      nonce: nonce,
      eth_address: eth_address
    }

    case Repo.get_by(__MODULE__, script_hash: attrs[:script_hash]) do
      nil -> %__MODULE__{}
      account -> account
    end
    |> changeset(attrs)
    |> Repo.insert_or_update!()
  end

  def sync_special_udt_balance(id) do
    with udt_id when is_integer(udt_id) <- UDT.ckb_account_id() do
      AccountUDT.realtime_update_balance(id, udt_id)
    end

    with udt_id when is_integer(udt_id) <- UDT.eth_account_id() do
      AccountUDT.realtime_update_balance(id, udt_id)
    end

    with udt_id when is_integer(udt_id) <- UDT.yok_account_id() do
      AccountUDT.update_erc20_balance!(id, udt_id)
    end
  end
end
