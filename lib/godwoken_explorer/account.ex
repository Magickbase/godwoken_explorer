defmodule GodwokenExplorer.Account do
  use GodwokenExplorer, :schema

  import Ecto.Changeset

  @primary_key {:id, :integer, autogenerate: false}
  schema "accounts" do
    field :ckb_address, :binary
    field :ckb_lock_script, :map
    field :eth_address, :binary
    field :script_hash, :binary
    field :script, :map
    field :nonce, :integer
    field :type, Ecto.Enum, values: [:meta_contract, :udt, :user, :polyjuice_root, :polyjuice_contract]
    field :layer2_tx, :binary
    has_many :account_udts, GodwokenExplorer.AccountUDT

    timestamps()
  end

  @doc false
  def changeset(account, attrs) do
    account
    |> cast(attrs, [:id, :ckb_address, :ckb_lock_script, :eth_address, :script_hash, :script, :nonce, :type, :layer2_tx])
    |> validate_required([:id, :script_hash, :script, :nonce, :type])
  end

  def create_or_update_account(attrs) do
    case Repo.get(__MODULE__, attrs[:id]) do
      nil -> %__MODULE__{}
      account -> account
    end
    |> changeset(attrs)
    |> Repo.insert_or_update()
    |> case do
      {:ok, account} -> {:ok, account}
      {:error, _} -> {:error, nil}
    end
  end

  def count() do
    from(
      a in Account,
      select: fragment("COUNT(*)")
    ) |> Repo.one(timeout: :infinity)
  end

  def update_meta_contract(global_state) do
    with meta_contract when not is_nil(meta_contract) <- Repo.get(Account, 0) do
      atom_script = for {key, val} <- meta_contract.script, into: %{}, do: {String.to_atom(key), val}
      new_script = atom_script |> Map.merge(global_state)
      meta_contract
      |> Ecto.Changeset.change(script: new_script)
      |> Repo.update()
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
      %Account{type: :meta_contract}  ->
      %{meta_contract:
        %{
          account_merkle_state: account.script["account_merkle_state"],
          block_merkle_state: account.script["block_merkle_state"],
          reverted_block_root: account.script["reverted_block_root"],
          last_finalized_block_number: account.script["last_finalized_block_number"],
          status: account.script["status"]
        }
      }
      %Account{type: :user}  ->
        udt_list = AccountUDT.list_udt_by_account_id(id)
        %{ user: %{
            eth_addr: account.eth_address,
            nonce: account.nonce |> Integer.to_string(),
            ckb_lock_script: account.ckb_lock_script,
            udt_list: udt_list
        }
      }
      %Account{type: :polyjuice_root}  ->
        %{
          polyjuice: %{
            script: account.script
          }
        }
      %Account{type: :polyjuice_contract} ->
        %{
          smart_contract: %{tx_hash: "0x3bd26903a0c8c418d1fba9be7eb13d088b8e68dc1f1d34941c8916246532cccf"}
        }
      %Account{type: :udt} ->
        udt = Repo.get(UDT, id)
        holders = UDT.count_holder(id)
        %{
          sudt: %{
            name: udt.name,
            symbol: udt.symbol,
            decimal: udt.decimal |> Integer.to_string(),
            supply: (udt.supply || Decimal.new(0)) |> Decimal.to_string(),
            holders: holders |> Integer.to_string(),
            type_script: udt.type_script
          }
        }
    end |> Map.merge(base_map)
  end

  def search(keyword) do
    from(a in Account, where: a.eth_address == ^keyword) |> Repo.one()
  end

  def bind_ckb_lock_script(lock_script, script_hash) do
    Repo.get_by(Account, script_hash: script_hash)
    |> Ecto.Changeset.change(%{ckb_lock_script: lock_script})
    |> Repo.update!()
  end
end
