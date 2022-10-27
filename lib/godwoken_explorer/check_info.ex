defmodule GodwokenExplorer.CheckInfo do
  @moduledoc """
  Last synced tip block number and current hash for rollback.
  """

  use GodwokenExplorer, :schema

  @typedoc """
  *  `block_hash` - The current sync block hash.
  *  `tip_block_number` - Current tip block number.
  *  `type` - To filter sync worker.
  """

  @type t :: %__MODULE__{
          block_hash: String.t(),
          tip_block_number: non_neg_integer(),
          type: String.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  @derive {Jason.Encoder, except: [:__meta__]}
  schema "check_infos" do
    field :block_hash, :string
    field :tip_block_number, :integer
    field :type, Ecto.Enum, values: [:main_deposit, :fix_history_deposit]

    timestamps()
  end

  @doc false
  def changeset(check_info, attrs) do
    check_info
    |> cast(attrs, [:tip_block_number, :block_hash, :type])
    |> validate_required([:tip_block_number, :block_hash, :type])
  end

  def create_or_update_info(attrs) do
    case Repo.get_by(__MODULE__, type: attrs[:type]) do
      nil ->
        %__MODULE__{}
        |> changeset(attrs)
        |> Repo.insert()

      check_info ->
        check_info
        |> changeset(attrs)
        |> Repo.update()
    end
  end

  def rollback!(check_info) do
    check_info
    |> Repo.history()
    |> List.first()
    |> Repo.revert()

    check_info
    |> Repo.history()
    |> Enum.take(2)
    |> Enum.each(fn info ->
      Repo.delete!(info)
    end)
  end
end
