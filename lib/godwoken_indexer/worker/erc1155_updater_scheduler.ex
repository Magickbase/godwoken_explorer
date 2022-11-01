defmodule GodwokenIndexer.Worker.ERC1155UpdaterScheduler do
  @moduledoc """
  Fetch ERC1155 metadata.
  """

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

    unfetched_udts = get_unfetched_udts(shift_seconds) |> Repo.all() |> process_struct()
    fetch_and_update(unfetched_udts)
  end

  def fetch_and_update(unfetched_udts) do
    unfetched_udts_hashes = Enum.map(unfetched_udts, fn udt -> udt.contract_address_hash end)

    {:ok, fetched_returns} = MetadataRetriever.get_functions_of(unfetched_udts_hashes)

    need_update_list =
      Enum.zip(unfetched_udts, fetched_returns)
      |> Enum.map(fn {c, f} ->
        if c.contract_address_hash == f.contract_address_hash do
          c
          |> Map.merge(f)
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
        else
          c
        end
      end)

    need_update_fetched_list =
      need_update_list
      |> Enum.filter(fn nu -> not is_nil(nu.name) and not is_nil(nu.symbol) end)

    _need_retries_list =
      need_update_list
      |> Enum.filter(fn nu -> is_nil(nu.name) or is_nil(nu.symbol) end)
      |> Enum.map(fn nu -> nu.contract_address_hash |> to_string() end)

    return =
      Import.insert_changes_list(
        need_update_fetched_list
        |> Enum.map(fn udt -> Map.delete(udt, :contract_address_hash) end),
        for: UDT,
        timestamps: import_timestamps(),
        on_conflict: {:replace, [:name, :symbol, :updated_at, :is_fetched]},
        conflict_target: :id
      )

    return
  end

  def get_unfetched_udts(shift_seconds)
      when shift_seconds > 0 and is_integer(shift_seconds) do
    datetime = Timex.now() |> Timex.shift(seconds: -shift_seconds)

    from(u in UDT,
      where:
        u.type == :native and u.eth_type == :erc1155 and
          u.updated_at > ^datetime,
      order_by: [asc: u.updated_at]
    )
  end

  def process_struct(struct_list) do
    struct_list
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
