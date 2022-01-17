defmodule GodwokenExplorer.PolyjuiceCreator do
  use GodwokenExplorer, :schema

  import Ecto.Changeset

  schema "polyjuice_creators" do
    field(:code_hash, :binary)
    field(:hash_type, :string)
    field(:script_args, :binary)
    field(:tx_hash, :binary)
    field(:fee_amount, :decimal)
    field(:fee_udt_id, :integer)

    belongs_to(:transaction, GodwokenExplorer.Transaction,
      foreign_key: :tx_hash,
      references: :hash,
      define_field: false
    )

    belongs_to(:udt, GodwokenExplorer.UDT,
      foreign_key: :fee_udt_id,
      references: :id,
      define_field: false
    )

    timestamps()
  end

  @doc false
  def changeset(polyjuice_creator, attrs) do
    polyjuice_creator
    |> cast(attrs, [:code_hash, :hash_type, :script_args, :fee_amount, :fee_udt_id])
    |> validate_required([:code_hash, :hash_type, :script_args, :fee_amount, :fee_udt_id])
  end

  def create_polyjuice_creator(attrs) do
    %PolyjuiceCreator{}
    |> PolyjuiceCreator.changeset(attrs)
    |> Ecto.Changeset.put_change(:tx_hash, attrs[:hash])
    |> Repo.insert()
  end
end
