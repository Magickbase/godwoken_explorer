defmodule GodwokenExplorer.DepositHistory do
  use GodwokenExplorer, :schema

  @derive {Jason.Encoder, except: [:__meta__]}
  schema "deposit_histories" do
    field :script_hash, :binary
    field :amount, :decimal
    field :udt_id, :integer
    field :layer1_block_number, :integer
    field :layer1_tx_hash, :binary
    field :layer1_output_index, :integer
    field :ckb_lock_hash, :binary
    field :timestamp, :utc_datetime_usec

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
      :timestamp
    ])
    |> validate_required([
      :layer1_block_number,
      :layer1_tx_hash,
      :udt_id,
      :amount,
      :script_hash,
      :layer1_output_index,
      :ckb_lock_hash,
      :timestamp
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
        AccountUDT.sync_balance!(%{account_id: account.id, udt_id: history.udt_id})
      end

      Repo.delete!(history)
    end)
  end

  def group_udt_amount(start_time, end_time) do
    condition =
      if start_time do
        dynamic([dh], dh.inserted_at >= ^start_time and dh.inserted_at < ^end_time)
      else
        dynamic([dh], dh.inserted_at < ^end_time)
      end

    from(dh in DepositHistory,
      where: ^condition,
      group_by: dh.udt_id,
      select: {dh.udt_id, sum(dh.amount)}
    )
    |> Repo.all()
  end
end
