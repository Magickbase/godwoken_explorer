defmodule GodwokenIndexer.Worker.ERC721UpdaterScheduler do
  use Oban.Worker, queue: :default

  import Ecto.Query
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
    shift_seconds = 24 * 60 * 60

    unfetched_udts = get_unfetched_udts(shift_seconds) |> Repo.all() |> process_fields()
    fetch_and_update(unfetched_udts)
  end

  def fetch_and_update(unfetched_udts) do
    unfetched_udts
    |> Enum.chunk_every(10)
    |> Enum.map(fn chunk_unfetched_udts ->
      need_update_list =
        Task.async_stream(
          chunk_unfetched_udts,
          fn chunk_unfetched_udt ->
            contract_address_hash = chunk_unfetched_udt.contract_address_hash |> to_string()

            return = MetadataRetriever.get_functions_of(contract_address_hash)

            need_update =
              chunk_unfetched_udt
              |> Map.merge(return)
              |> Map.merge(%{is_fetched: true})
              |> Map.take([
                :id,
                :name,
                :totalSupply,
                :decimals,
                :symbol,
                :update_at,
                :contract_address_hash,
                :is_fetched
              ])

            need_update
          end,
          timeout: 30_000
        )
        |> Enum.map(fn {:ok, r} -> r end)

      need_update_fetched_list =
        need_update_list
        |> Enum.filter(fn nu -> not is_nil(nu.name) and not is_nil(nu.symbol) end)

      _need_retries_list =
        need_update_list
        |> Enum.filter(fn nu -> is_nil(nu.name) or is_nil(nu.symbol) end)
        |> Enum.map(fn nu -> nu.contract_address_hash |> to_string() end)

      Import.insert_changes_list(
        need_update_fetched_list
        |> Enum.map(fn udt -> Map.delete(udt, :contract_address_hash) end),
        for: UDT,
        timestamps: import_timestamps(),
        on_conflict: {:replace, [:name, :symbol, :updated_at, :is_fetched]},
        conflict_target: :id
      )
    end)
  end

  def get_unfetched_udts(shift_seconds)
      when shift_seconds > 0 and is_integer(shift_seconds) do
    datetime = Timex.now() |> Timex.shift(seconds: -shift_seconds)

    from(u in UDT,
      where:
        u.type == :native and u.eth_type == :erc721 and
          (is_nil(u.name) or is_nil(u.symbol)) and (is_nil(u.is_fetched) or u.is_fetched == false) and
          u.updated_at > ^datetime,
      order_by: [asc: u.updated_at]
    )
  end

  def process_fields(struct_lists) do
    struct_lists
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
        :contract_address_hash,
        :is_fetched
      ])
    end)
  end

  def process_limit(query, limit_value)
      when is_nil(limit_value) or (is_integer(limit_value) and limit_value > 0) do
    case limit_value do
      nil -> query
      _ -> query |> limit(^limit_value)
    end
  end
end
