defmodule GodwokenExplorer.KeyValue do
  use Ecto.Schema
  import Ecto.Changeset
  alias GodwokenExplorer.Repo

  schema "key_values" do
    field :key, Ecto.Enum, values: [:last_udt_supply_at, :last_account_total_count]
    field :value, :string

    timestamps()
  end

  @doc false
  def changeset(key_value, attrs) do
    key_value
    |> cast(attrs, [:key, :value])
    |> validate_required([:key, :value])
  end

  def exist?(key) do
    Repo.get_by(KeyValue, key: key) != nil
  end
end
