defmodule GodwokenIndexer.Worker.ERC721UpdaterScheduler do
  use Oban.Worker, queue: :default

  import Ecto.Query, only: [from: 2]

  alias GodwokenExplorer.{Repo, UDT}

  alias GodwokenIndexer.Worker.ERC721Updater, as: ERC721UpdaterWorker

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    do_perform()
    :ok
  end

  def do_perform() do
    datetime = Timex.now() |> Timex.shift(hours: -1)

    unfetched_udts =
      from(u in UDT,
        where:
          u.type == :native and u.eth_type == :erc721 and
            (is_nil(u.name) or is_nil(u.symbol)) and
            u.updated_at < ^datetime,
        order_by: [desc: u.id]
      )
      |> Repo.all()

    Enum.chunk_every(unfetched_udts, 50)
    |> Enum.map(fn chunk_unfetched_udts ->
      chunk_unfetched_udts
      |> Enum.map(fn u ->
        u
        |> Map.from_struct()
        |> Map.take([
          :id,
          :name,
          :totalSupply,
          :decimals,
          :symbol,
          :update_at,
          :contract_address_hash
        ])
      end)
    end)
    |> Enum.each(fn chunk_unfetched_udts ->
      ERC721UpdaterWorker.new(%{chunk_unfetched_udts: chunk_unfetched_udts}) |> Oban.insert()
    end)
  end
end
