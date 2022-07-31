defmodule GodwokenIndexer.Worker.UDTUpdater do
  use Oban.Worker, queue: :default

  import Ecto.Query, only: [from: 2]

  alias GodwokenExplorer.{Chain, Repo, UDT}
  alias GodwokenExplorer.Token.MetadataRetriever

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    datetime = Timex.now() |> Timex.shift(hours: -1)

    query =
      from(u in UDT,
        where:
          u.type == :native and u.eth_type == :erc20 and not is_nil(u.name) and
            u.updated_at < ^datetime,
        select: u.contract_address_hash
      )

    stream = GodwokenExplorer.Repo.stream(query, max_rows: 50)

    GodwokenExplorer.Repo.transaction(
      fn ->
        hashes = Enum.to_list(stream)
        {:ok, metadata_list} = MetadataRetriever.get_functions_of(hashes)

        Enum.each(metadata_list, fn %{contract_address_hash: contract_address_hash} = metadata ->
          udt_to_update =
            UDT
            |> Repo.get_by(contract_address_hash: contract_address_hash)
            |> Repo.preload(:account)

          {:ok, _} =
            Chain.update_udt(
              %{
                udt_to_update
                | updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
              },
              metadata
            )
        end)
      end,
      timeout: :infinity
    )

    :ok
  end
end
