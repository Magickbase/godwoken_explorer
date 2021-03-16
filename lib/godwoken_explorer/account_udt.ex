defmodule GodwokenExplorer.AccountUDT do
  use GodwokenExplorer, :schema

  import Ecto.Changeset

  alias GodwokenExplorer.Chain.Events.Publisher

  schema "account_udts" do
    field :balance, :decimal
    belongs_to(:account, GodwokenExplorer.Account, foreign_key: :account_id, references: :id)
    belongs_to(:udt, GodwokenExplorer.UDT, foreign_key: :udt_id, references: :id)

    timestamps()
  end

  @doc false
  def changeset(account_udt, attrs) do
    account_udt
    |> cast(attrs, [:account_id, :udt_id, :balance])
    |> validate_required([:account_id, :udt_id, :balance])
  end

  def create_or_update_account_udt(attrs) do
    case Repo.get_by(__MODULE__, %{account_id: attrs[:account_id], udt_id: attrs[:udt_id]}) do
      nil -> %__MODULE__{}
      account_udt -> account_udt
    end
    |> changeset(attrs)
    |> Repo.insert_or_update()
    |> case do
      {:ok, account_udt} ->
        account_api_data = account_udt.account_id |> Account.find_by_id() |> Account.account_to_view()
        Publisher.broadcast([{:accounts, account_api_data}], :realtime)
        {:ok, account_udt}
      {:error, _} -> {:error, nil}
    end
  end

  def list_udt_by_account_id(account_id) do
    from(au in AccountUDT,
      join: u in UDT,
      on: [id: au.udt_id],
      where: u.id != 1 and au.account_id == ^account_id,
      select: %{name: u.name, icon: u.icon, balance: au.balance, decimal: u.decimal}
    )
    |> Repo.all()
    |> Enum.map(fn u -> %{u | balance: Decimal.to_string(u.balance)} end)
  end
end
