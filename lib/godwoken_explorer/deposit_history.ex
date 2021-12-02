defmodule GodwokenExplorer.DepositHistory do
  use GodwokenExplorer, :schema

  schema "deposit_histories" do
    field :script_hash, :binary
    field :amount, :decimal
    field :udt_id, :integer
    field :layer1_block_number, :integer
    field :layer1_tx_hash, :binary
    field :layer1_output_index, :integer
    field :ckb_lock_hash, :binary

    timestamps()
  end

  @doc false
  def changeset(deposit_history, attrs) do
    deposit_history
    |> cast(attrs, [:layer1_block_number, :layer1_tx_hash, :udt_id, :amount, :script_hash, :layer1_output_index, :ckb_lock_hash])
    |> validate_required([:layer1_block_number, :layer1_tx_hash, :udt_id, :amount, :script_hash, :layer1_output_index, :ckb_lock_hash])
  end

  def create!(attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert!
  end

  def rollback!(layer1_block_number) do
    from(d in DepositHistory, where: d.layer1_block_number == ^layer1_block_number)
    |> Repo.all()
    |> Enum.each(fn history ->
      exist_count = from(d in DepositHistory, where: d.script_hash == ^history.script_hash) |> Repo.aggregate(:count)
      account = Repo.get_by(Account, script_hash: history.scrript_hash)
      if exist_count == 1 do
        Repo.delete!(account)
      else
        AccountUDT.sync_balance!(account.id, history.udt_id)
      end
      Repo.delete!(history)
    end)
  end
end
