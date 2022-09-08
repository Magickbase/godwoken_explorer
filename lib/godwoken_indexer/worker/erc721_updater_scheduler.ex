defmodule GodwokenIndexer.Worker.ERC721UpdaterScheduler do
  use Oban.Worker, queue: :default

  import Ecto.Query, only: [from: 2]
  import GodwokenRPC.Util, only: [import_timestamps: 0]
  alias GodwokenExplorer.Chain.{Import}
  alias GodwokenExplorer.{Repo, UDT}
  alias GodwokenExplorer.Token.MetadataRetriever

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    do_perform()
    :ok
  end

  def do_perform() do
    get_unfetched_udts()
    |> Enum.chunk_every(10)
    |> Enum.map(fn chunk_unfetched_udts ->
      need_update_list =
        Task.async_stream(chunk_unfetched_udts, fn chunk_unfetched_udt ->
          contract_address_hash = chunk_unfetched_udt.contract_address_hash
          return = MetadataRetriever.get_functions_of(contract_address_hash)

          need_update =
            chunk_unfetched_udt
            |> Map.merge(return)
            |> Map.take([
              :id,
              :name,
              :totalSupply,
              :decimals,
              :symbol,
              :update_at,
              :contract_address_hash
            ])

          need_update
        end)
        |> Enum.map(fn {:ok, r} -> r end)

      Import.insert_changes_list(
        need_update_list |> Enum.map(fn udt -> Map.delete(udt, :contract_address_hash) end),
        for: UDT,
        timestamps: import_timestamps(),
        on_conflict: {:replace, [:name, :symbol, :updated_at]},
        conflict_target: :id
      )
    end)
  end

  def get_unfetched_udts() do
    datetime = Timex.now() |> Timex.shift(hours: -1)

    from(u in UDT,
      where:
        u.type == :native and u.eth_type == :erc721 and
          (is_nil(u.name) or is_nil(u.symbol)) and
          u.updated_at < ^datetime,
      order_by: [desc: u.id],
      limit: 100
    )
    |> Repo.all()
    |> Enum.map(fn chunk_unfetched_udt ->
      chunk_unfetched_udt
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
  end
end
