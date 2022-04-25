defmodule GodwokenExplorer.DailyStat do
  use GodwokenExplorer, :schema

  require Logger

  schema "daily_stats" do
    field :avg_block_size, :integer
    field :avg_block_time, :float
    field :avg_gas_used, :decimal
    field :avg_gas_limit, :decimal
    field :date, :date
    field :erc20_transfer_count, :integer
    field :total_block_count, :integer
    field :total_txn, :integer

    timestamps()
  end

  @doc false
  def changeset(daily_stat, attrs) do
    daily_stat
    |> cast(attrs, [
      :date,
      :total_txn,
      :avg_block_time,
      :avg_block_size,
      :total_block_count,
      :erc20_transfer_count,
      :avg_gas_limit,
      :avg_gas_used
    ])
    |> validate_required([
      :date,
      :total_txn,
      :avg_block_time,
      :avg_block_size,
      :total_block_count,
      :erc20_transfer_count,
      :avg_gas_limit,
      :avg_gas_used
    ])
  end

  def insert_or_update(changes) do
    case Repo.get_by(__MODULE__, date: changes[:date]) do
      nil -> %__MODULE__{}
      daily_stat -> daily_stat
    end
    |> changeset(changes)
    |> Repo.insert_or_update()
  end

  def by_date_range(earliest, latest) do
    query =
      from(stat in __MODULE__,
        where: stat.date >= ^earliest and stat.date <= ^latest,
        order_by: [desc: :date]
      )

    Repo.all(query)
  end
end
