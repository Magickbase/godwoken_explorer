defmodule GodwokenExplorer.PolyjuiceCreator do
  @moduledoc """
  Parse Polyjuice Creator args and belongs to Transaction.

  This transaction will generate polyjuice creator.
  """
  use GodwokenExplorer, :schema

  import Ecto.Changeset

  alias GodwokenExplorer.Chain.Hash

  @typedoc """
   * `code_hash` - Layer2 account code_hash.
   * `hash_type` - Layer2 account hash_type.
   * `script_args` - Layer2 account script_args.
   * `fee_amount` - The tranasaction used fee.
   * `fee_registry_id` - The transaction registry by which account.
   * `tx_hash` - The transaction foreign key.
  """
  @type t :: %__MODULE__{
          code_hash: String.t(),
          hash_type: String.t(),
          script_args: String.t(),
          fee_amount: Decimal.t(),
          fee_registry_id: non_neg_integer(),
          tx_hash: Hash.Full.t(),
          transaction: %Ecto.Association.NotLoaded{} | Transaction.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

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
