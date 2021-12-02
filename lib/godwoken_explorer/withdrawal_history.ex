defmodule GodwokenExplorer.WithdrawalHistory do
  use GodwokenExplorer, :schema

  schema "withdrawal_histories" do
    field :block_hash, :binary
    field :block_number, :integer
    field :layer1_block_number, :integer
    field :l2_script_hash, :binary
    field :layer1_output_index, :integer
    field :layer1_tx_hash, :binary
    field :owner_lock_hash, :binary
    field :payment_lock_hash, :binary
    field :sell_amount, :decimal
    field :sell_capacity, :decimal
    field :udt_script_hash, :binary

    timestamps()
  end

  @doc false
  def changeset(withdrawal_history, attrs) do
    withdrawal_history
    |> cast(attrs, [:layer1_block_number, :layer1_tx_hash, :layer1_output_index, :l2_script_hash, :block_hash, :block_number, :udt_script_hash, :sell_amount, :sell_capacity, :owner_lock_hash, :payment_lock_hash])
    |> validate_required([:layer1_block_number, :layer1_tx_hash, :layer1_output_index, :l2_script_hash, :block_hash, :block_number, :udt_script_hash, :sell_amount, :sell_capacity, :owner_lock_hash, :payment_lock_hash])
  end

  def create(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert
  end
end
