defmodule GodwokenExplorer.CheckInfo do
  use GodwokenExplorer, :schema

  schema "check_infos" do
    field :block_hash, :string
    field :tip_block_number, :integer
    field :type, Ecto.Enum,
      values: [:main_deposit, :fix_history_deposit]

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
        |> Repo.insert

      check_info ->
        check_info
        |> changeset(attrs)
        |> Repo.update
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
