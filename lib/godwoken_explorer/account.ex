defmodule GodwokenExplorer.Account do
  use GodwokenExplorer, :schema

  import Ecto.Changeset

  @primary_key {:id, :integer, autogenerate: false}
  schema "accounts" do
    field :ckb_address, :binary
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
    |> cast(attrs, [:id, :ckb_address, :eth_address, :script_hash, :script, :nonce, :type, :layer2_tx])
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
    meta_contract = Repo.get(Account, 0)
    atom_script = for {key, val} <- meta_contract.script, into: %{}, do: {String.to_atom(key), val}
    if atom_script[:block_merkle_state][:block_count] != global_state[:block_merkle_state][:block_count] do
      new_script = atom_script |> Map.merge(global_state)
      meta_contract
      |> Ecto.Changeset.change(script: new_script)
      |> Repo.update()
    end
  end
end
