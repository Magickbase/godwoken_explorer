defmodule GodwokenExplorer.KeyValue do
  @moduledoc """
  To cache some key persistence in db.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias GodwokenExplorer.Repo

  @typedoc """
  *  `key` - Uniq key to get value.
  *  `value` - String value.
  """

  @type t :: %__MODULE__{
          key: String.t(),
          value: String.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  schema "key_values" do
    field :key, Ecto.Enum, values: [:last_udt_supply_at, :last_account_total_count]
    field :value, :string

    timestamps()
  end

  @doc false
  def changeset(key_value, attrs) do
    key_value
    |> cast(attrs, [:key, :value])
    |> validate_required([:key])
  end

  def exist?(key) do
    Repo.get_by(KeyValue, key: key) != nil
  end
end
