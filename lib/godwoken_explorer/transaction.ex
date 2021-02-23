defmodule GodwokenExplorer.Transaction do
  use GodwokenExplorer, :schema

  import Ecto.Changeset

  @primary_key {:hash, :binary, autogenerate: false}
  schema "transactions" do
    field :args, :binary
    field :from_account_id, :integer
    field :nonce, :integer
    field :status, Ecto.Enum, values: [:unfinalized, :finalized], default: :unfinalized
    field :to_account_id, :integer
    field :type, Ecto.Enum, values: [:sudt, :polyjuice_creator, :polyjuice, :withdrawal]
    field :block_number, :integer
    field :block_hash, :binary

    belongs_to(:block, Block, foreign_key: :block_hash, references: :hash, define_field: false)

    timestamps()
  end

  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [:hash, :block_hash, :type, :from_account_id, :to_account_id, :nonce, :args, :status, :block_number])
    |> validate_required([:hash, :from_account_id, :to_account_id, :nonce, :args, :status, :block_number])
  end

  def create_transaction(%{type: :sudt} = attrs) do
    %Transaction{}
    |> Transaction.changeset(attrs)
    |> Ecto.Changeset.put_change(:block_hash, attrs[:block_hash])
    |> Repo.insert!()
    UDTTransfer.create_udt_transfer(attrs)
  end

  def create_transaction(%{type: :polyjuice_creator} = attrs) do
    %Transaction{}
    |> Transaction.changeset(attrs)
    |> Ecto.Changeset.put_change(:block_hash, attrs[:block_hash])
    |> Repo.insert!()
    PolyjuiceCreator.create_polyjuice_creator(attrs)
  end

  def create_transaction(%{type: :withdrawal} = attrs) do
    %Transaction{}
    |> Transaction.changeset(attrs)
    |> Repo.insert!()
  end
end
