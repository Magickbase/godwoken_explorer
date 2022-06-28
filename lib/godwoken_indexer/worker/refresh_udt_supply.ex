defmodule GodwokenIndexer.Worker.RefreshUDTSupply do
  use Oban.Worker, queue: :default

  import Ecto.Query, only: [from: 2]

  alias GodwokenExplorer.{Account, Repo, KeyValue, DepositHistory, WithdrawalHistory, UDT}

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
      deposit_udt_ids = DepositHistory.distinct_udt(start_time, end_time)
      withdrawal_udt_ids = WithdrawalHistory.distinct_udt(start_time, end_time)
      udt_ids = deposit_udt_ids ++ withdrawal_udt_ids

      Repo.transaction(fn ->
        from(u in UDT,
          join: a in Account,
          on: a.id == u.bridge_account_id,
          where: u.id in ^udt_ids,
          select: {u, a.eth_address}
        )
        |> Repo.all()
        |> Enum.each(fn {u, eth_address} ->
          supply = UDT.eth_call_total_supply(eth_address)

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
