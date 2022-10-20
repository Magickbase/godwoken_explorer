defmodule GodwokenExplorer.DailyStat do
  @moduledoc """
  Chain data statistics every day.
  """

  use GodwokenExplorer, :schema

  require Logger

  @typedoc """
     * `avg_block_size` - Daily all blocks average size.
     * `avg_block_time` - Daily all block average timestamp .
     * `avg_gas_used` - Daily all blocks average used gas.
     * `avg_gas_limit` - Daily all blocks average limited gas.
     * `date` - When.
     * `erc20_transfer_count` - Daily token transfer count.
     * `total_block_count` - Daily mined block count.
     * `total_txn` - Daily total transction count.
  """

  @type t :: %__MODULE__{
          avg_block_size: non_neg_integer(),
          avg_block_time: float(),
          avg_gas_used: Decimal.t(),
          avg_gas_limit: Decimal.t(),
          date: DateTime.t(),
          erc20_transfer_count: non_neg_integer(),
          total_block_count: non_neg_integer(),
          total_txn: non_neg_integer(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

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
