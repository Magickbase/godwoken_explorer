defmodule GodwokenExplorer.UDT do
  use GodwokenExplorer, :schema

  import Ecto.Changeset

  @primary_key {:id, :integer, autogenerate: false}
  schema "udts" do
    field :decimal, :integer
    field :name, :string
    field :symbol, :string
    field :icon, :string
    field :supply, :decimal
    field :type_script, :map
    field :script_hash, :binary

    timestamps()
  end

  @doc false
  def changeset(udt, attrs) do
    udt
    |> cast(attrs, [:id, :name, :symbol, :decimal, :icon, :supply, :type_script, :script_hash])
    |> validate_required([:id, :script_hash])
  end

  def find_or_create_by(attrs) do
    case Repo.get_by(__MODULE__, %{script_hash: attrs[:script_hash], id: attrs[:id]}) do
      nil ->
        %__MODULE__{}
        |> changeset(attrs)
        |> Repo.insert()
      udt -> {:ok, udt}
    end
  end

  def count_holder(udt_id) do
    from(au in AccountUDT, where: au.udt_id == ^udt_id) |> Repo.aggregate(:count)
  end
end
