defmodule GodwokenExplorer.DepositHistory do
  @moduledoc """
  Account deposit from layer1.
  """

  use GodwokenExplorer, :schema

  alias GodwokenExplorer.Chain.Hash

  @typedoc """
     * `script_hash` - Layer2 account script hash.
     * `amount` - Deposit amount.
     * `udt_id` - The UDT table foreign key.
     * `layer1_block_number` - Deposit at which layer1 block.
     * `layer1_tx_hash` - Deposit at which layer1 transaction.
     * `layer1_output_index` - Deposit transaction's output index.
     * `ckb_lock_hash` - Layer1 account's lock hash.
     * `timestamp` - Layer1 transaction's timestamp.
     * `capacity` - Layer1 transaction's output's capacity.
     * `udt_script_hash` - The udt in layer1's script hash.
  """

  @type t :: %__MODULE__{
          script_hash: Hash.Full.t(),
          amount: Decimal.t(),
          udt_id: non_neg_integer(),
          layer1_block_number: non_neg_integer(),
          layer1_tx_hash: Hash.Full.t(),
          layer1_output_index: non_neg_integer(),
          ckb_lock_hash: Hash.Full.t(),
          timestamp: DateTime.t(),
          capacity: Decimal.t(),
          udt_script_hash: Hash.Full.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }
  @derive {Jason.Encoder, except: [:__meta__]}
  schema "deposit_histories" do
    field :script_hash, Hash.Full
    field :amount, :decimal
    field :udt_id, :integer
    field :layer1_block_number, :integer
    field :layer1_tx_hash, Hash.Full
    field :layer1_output_index, :integer
    field :ckb_lock_hash, Hash.Full
    field :timestamp, :utc_datetime_usec
    field :capacity, :decimal
    field :udt_script_hash, Hash.Full

    belongs_to(:udt, UDT, foreign_key: :udt_id, references: :id, define_field: false)

    timestamps()
  end

  @doc false
  def changeset(deposit_history, attrs) do
    deposit_history
    |> cast(attrs, [
      :layer1_block_number,
      :layer1_tx_hash,
      :udt_id,
      :amount,
      :script_hash,
      :layer1_output_index,
      :ckb_lock_hash,
      :timestamp,
      :capacity,
      :udt_script_hash
    ])
    |> validate_required([
      :layer1_block_number,
      :layer1_tx_hash,
      :udt_id,
      :udt_script_hash,
      :amount,
      :script_hash,
      :layer1_output_index,
      :ckb_lock_hash,
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
    from(d in DepositHistory, where: d.layer1_block_number == ^layer1_block_number)
    |> Repo.all()
    |> Enum.each(fn history ->
      exist_count =
        from(d in DepositHistory, where: d.script_hash == ^history.script_hash)
        |> Repo.aggregate(:count)

      account = Repo.get_by(Account, script_hash: history.script_hash)

      if exist_count == 1 do
        Repo.delete!(account)
      else
        CurrentBridgedUDTBalance.sync_balance!(%{
          account_id: account.id,
          udt_id: history.udt_id,
          layer1_block_number: layer1_block_number
        })
      end

      Repo.delete!(history)
    end)
  end

  def distinct_udt(start_time, end_time) do
    condition =
      if start_time do
        dynamic([dh], dh.inserted_at >= ^start_time and dh.inserted_at < ^end_time)
      else
        dynamic([dh], dh.inserted_at < ^end_time)
      end

    from(dh in DepositHistory,
      where: ^condition,
      distinct: dh.udt_id,
      select: dh.udt_id
    )
    |> Repo.all()
  end
end
