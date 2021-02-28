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

  def create_account(attrs) do
    %Account{}
    |> Account.changeset(attrs)
    |> Repo.insert()
  end

  def list_not_exist_accounts(ids) do
    query = from account in "accounts",
              where: account.id in ^ids,
              select: account.id

    exist_ids = Repo.all(query)
    ids -- exist_ids
  end

end
