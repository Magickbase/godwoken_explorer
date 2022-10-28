defmodule GodwokenExplorer.WithdrawalHistory do
  @moduledoc """
  Account withdrawal to layer1.
  """
  use GodwokenExplorer, :schema

  alias GodwokenExplorer.Chain.Hash

  @typedoc """
     * `block_hash` - Withdraw at which layer2 block.
     * `block_number` - Withdraw at which layer2 block.
     * `layer1_block_number` - Deposit at which layer1 block.
     * `layer1_tx_hash` - Deposit at which layer1 transaction.
     * `layer1_output_index` - Deposit transaction's output index.
     * `l2_script_hash` - Layer2 account script hash.
     * `owner_lock_hash` - Layer1 owner lock hash.
     * `udt_script_hash` - The udt of layer1's script hash.
     * `amount` - Withdrawal amount.
     * `udt_id` - The UDT table foreign key.
     * `timestamp` - Layer1 transaction's timestamp.
     * `state` - Pending means just submit withrawal, not on chain;Available means can withrawal after a certain time;Succeed means withdrawal succeefully.
     * `capacity` - Layer1 transaction's output's capacity or ckb withdrawal amount.
  """

  @type t :: %__MODULE__{
          block_hash: Hash.Full.t(),
          block_number: non_neg_integer(),
          layer1_block_number: non_neg_integer(),
          layer1_tx_hash: Hash.Full.t(),
          layer1_output_index: non_neg_integer(),
          l2_script_hash: Hash.Full.t(),
          owner_lock_hash: Hash.Full.t(),
          udt_script_hash: Hash.Full.t(),
          udt_id: non_neg_integer(),
          amount: Decimal.t(),
          timestamp: DateTime.t(),
          state: String.t(),
          capacity: Decimal.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  @derive {Jason.Encoder, except: [:__meta__]}
  schema "withdrawal_histories" do
    field :block_hash, Hash.Full
    field :block_number, :integer
    field :layer1_block_number, :integer
    field :layer1_output_index, :integer
    field :layer1_tx_hash, Hash.Full
    field :l2_script_hash, Hash.Full
    field :owner_lock_hash, Hash.Full
    field :udt_script_hash, Hash.Full
    field :amount, :decimal
    field :udt_id, :integer
    field :timestamp, :utc_datetime_usec
    field :state, Ecto.Enum, values: [:pending, :available, :succeed]
    field :capacity, :decimal

    belongs_to(:udt, UDT, foreign_key: :udt_id, references: :id, define_field: false)

    timestamps()
  end

  @doc false
  def changeset(withdrawal_history, attrs) do
    withdrawal_history
    |> cast(attrs, [
      :layer1_block_number,
      :layer1_tx_hash,
      :layer1_output_index,
      :l2_script_hash,
      :block_hash,
      :block_number,
      :udt_script_hash,
      :owner_lock_hash,
      :amount,
      :udt_id,
      :timestamp,
      :state,
      :capacity
    ])
    |> validate_required([
      :layer1_block_number,
      :layer1_tx_hash,
      :layer1_output_index,
      :l2_script_hash,
      :block_hash,
      :block_number,
      :udt_script_hash,
      :owner_lock_hash,
      :amount,
      :udt_id,
      :timestamp,
      :capacity
    ])
    |> unique_constraint([:layer1_tx_hash, :layer1_block_number, :layer1_output_index])
  end

  def create_or_update_history!(attrs) do
    case Repo.get_by(__MODULE__,
           layer1_tx_hash: attrs[:layer1_tx_hash],
           layer1_block_number: attrs[:layer1_block_number],
           layer1_output_index: attrs[:layer1_output_index]
         ) do
      nil -> %__MODULE__{}
      history -> history
    end
    |> changeset(attrs)
    |> Repo.insert_or_update!()
  end

  def rollback!(layer1_block_number) do
    from(w in WithdrawalHistory, where: w.layer1_block_number == ^layer1_block_number)
    |> Repo.all()
    |> Enum.each(fn history ->
      Repo.delete!(history)
    end)
  end

  def search(keyword) do
    from(h in WithdrawalHistory,
      where: h.l2_script_hash == ^keyword or h.owner_lock_hash == ^keyword,
      order_by: [desc: :id]
    )
    |> Repo.all()
  end

  def update_available_state(latest_finalized_block_number) do
    from(h in WithdrawalHistory,
      where: h.block_number <= ^latest_finalized_block_number and h.state == :pending
    )
    |> Repo.update_all(set: [state: :available])
  end

  def distinct_udt(start_time, end_time) do
    condition =
      if start_time do
        dynamic(
          [wh],
          wh.inserted_at >= ^start_time and wh.inserted_at < ^end_time
        )
      else
        dynamic([wh], wh.inserted_at < ^end_time)
      end

    from(wh in WithdrawalHistory,
      where: ^condition,
      distinct: wh.udt_id,
      select: wh.udt_id
    )
    |> Repo.all()
  end
end
