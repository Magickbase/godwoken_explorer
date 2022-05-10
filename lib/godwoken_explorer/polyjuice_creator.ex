defmodule GodwokenExplorer.PolyjuiceCreator do
  use GodwokenExplorer, :schema

  import Ecto.Changeset

  @derive {Jason.Encoder, except: [:__meta__]}
  schema "polyjuice_creators" do
    field(:code_hash, :binary)
    field(:hash_type, :string)
    field(:script_args, :binary)
    field(:tx_hash, :binary)
    field(:fee_amount, :decimal)
    field(:fee_registry_id, :integer)

    belongs_to(:transaction, GodwokenExplorer.Transaction,
      foreign_key: :tx_hash,
      references: :hash,
      define_field: false
    )

    timestamps()
  end

  @doc false
  def changeset(polyjuice_creator, attrs) do
    polyjuice_creator
    |> cast(attrs, [:code_hash, :hash_type, :script_args, :fee_amount, :fee_registry_id])
    |> validate_required([:code_hash, :hash_type, :script_args, :fee_amount, :fee_registry_id])
    |> unique_constraint(:tx_hash)
  end

  def create_polyjuice_creator(attrs) do
    %PolyjuiceCreator{}
    |> PolyjuiceCreator.changeset(attrs)
    |> Ecto.Changeset.put_change(:tx_hash, attrs[:hash])
    |> Repo.insert(on_conflict: :nothing)
  end
end
