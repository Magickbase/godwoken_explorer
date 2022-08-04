defmodule GodwokenIndexer.Worker.UDTUpdater do
  use Oban.Worker, queue: :default

  import Ecto.Query, only: [from: 2]

  alias GodwokenExplorer.{Chain, Repo, UDT}
  alias GodwokenExplorer.Token.MetadataRetriever

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    datetime = Timex.now() |> Timex.shift(hours: -1)

    bridge_udt_ids =
      from(u in UDT, where: not is_nil(u.bridge_account_id), select: u.bridge_account_id)
      |> Repo.all()

    query =
      from(u in UDT,
        where:
          u.type == :native and u.eth_type == :erc20 and not is_nil(u.name) and
            u.updated_at < ^datetime
      )

    stream = GodwokenExplorer.Repo.stream(query, max_rows: 50)

    GodwokenExplorer.Repo.transaction(
      fn ->
        Enum.to_list(stream)
        |> Enum.each(fn udt ->
          metadata = MetadataRetriever.get_functions_of(udt.contract_address_hash)

          udt_to_update =
            udt
            |> Repo.preload(:account)

          if(udt_to_update.id in bridge_udt_ids) do
            {:ok, _} =
              Chain.update_udt(
                %{
                  udt_to_update
                  | updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
                },
                metadata |> Map.take([:supply, :decimal])
              )
          else
            {:ok, _} =
              Chain.update_udt(
                %{
                  udt_to_update
                  | updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
                },
                metadata
              )
          end
        end)
      end,
      timeout: :infinity
    )

    :ok
  end
end
