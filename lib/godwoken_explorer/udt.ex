defmodule GodwokenExplorer.UDT do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :integer, autogenerate: false}
  schema "udts" do
    field :decimal, :integer
    field :name, :string
    field :symbol, :string
    field :typescript_hash, :binary

    timestamps()
  end

  @doc false
  def changeset(udt, attrs) do
    udt
    |> cast(attrs, [:name, :symbol, :decimal, :typescript_hash])
    |> validate_required([:name, :symbol, :decimal, :typescript_hash])
  end
end
