defmodule GodwokenIndexer.Worker.RefreshUDTSupply do
  use Oban.Worker, queue: :default

  import Ecto.Query, only: [from: 2]

  alias GodwokenExplorer.{Repo, KeyValue, DepositHistory, WithdrawalHistory, UDT}
  alias Decimal, as: D

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    {key_value, start_time} =
      case Repo.get_by(KeyValue, key: :last_udt_supply_at) do
        nil ->
          {:ok, key_value} =
            %KeyValue{} |> KeyValue.changeset(%{key: :last_udt_supply_at}) |> Repo.insert()

          {key_value, nil}

        %KeyValue{value: value} = key_value when is_nil(value) ->
          {key_value, nil}

        %KeyValue{value: value} = key_value ->
          {key_value, value |> Timex.parse!("{ISO:Extended}")}
      end

    end_time = Timex.beginning_of_day(Timex.now())

    if start_time != end_time do
      deposits = DepositHistory.group_udt_amount(start_time, end_time) |> Map.new()
      withdrawals = WithdrawalHistory.group_udt_amount(start_time, end_time) |> Map.new()
      udt_amounts = Map.merge(deposits, withdrawals, fn _k, v1, v2 -> D.add(v1, v2) end)
      udt_ids = udt_amounts |> Map.keys()

      Repo.transaction(fn ->
        from(u in UDT, where: u.id in ^udt_ids)
        |> Repo.all()
        |> Enum.each(fn u ->
          supply =
            udt_amounts
            |> Map.fetch!(u.id)
            |> D.add(u.supply || D.new(0))

          UDT.changeset(u, %{
            supply: supply
          })
          |> Repo.update!()
        end)

        KeyValue.changeset(key_value, %{value: end_time |> Timex.format!("{ISO:Extended}")})
        |> Repo.update!()
      end)
    end

    :ok
  end
end
