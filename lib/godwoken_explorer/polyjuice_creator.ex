defmodule GodwokenExplorer.PolyjuiceCreator do
  use GodwokenExplorer, :schema

  import Ecto.Changeset

  alias GodwokenExplorer.Chain.Hash

  @derive {Jason.Encoder, except: [:__meta__]}
  schema "polyjuice_creators" do
    field(:code_hash, :binary)
    field(:hash_type, :string)
    field(:script_args, :binary)
    field(:fee_amount, :decimal)
    field(:fee_registry_id, :integer)

    belongs_to(:transaction, GodwokenExplorer.Transaction,
      foreign_key: :tx_hash,
      references: :hash,
      type: Hash.Full
    )

    timestamps()
  end

  @doc false
  def changeset(polyjuice_creator, attrs) do
    polyjuice_creator
    |> cast(attrs, [:tx_hash, :code_hash, :hash_type, :script_args, :fee_amount, :fee_registry_id])
    |> validate_required([:tx_hash, :code_hash, :hash_type, :script_args, :fee_amount])
    |> unique_constraint(:tx_hash)
  end

  def create_polyjuice_creator(attrs) do
    %PolyjuiceCreator{}
    |> PolyjuiceCreator.changeset(attrs)
    |> Ecto.Changeset.put_change(:tx_hash, attrs[:hash])
    |> Repo.insert(on_conflict: :nothing)
  end
end
