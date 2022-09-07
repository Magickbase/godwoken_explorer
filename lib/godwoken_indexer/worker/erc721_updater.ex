defmodule GodwokenIndexer.Worker.ERC721Updater do
  use Oban.Worker, queue: :default

  import Ecto.Query, only: [from: 2]

  alias GodwokenExplorer.{Repo, UDT}
  alias GodwokenExplorer.Token.MetadataRetriever
  import GodwokenRPC.Util, only: [import_timestamps: 0]
  alias GodwokenExplorer.Chain.{Import}

  @impl Oban.Worker

  def perform(%Oban.Job{}) do
    do_perform()
    :ok
  end

  def do_perform() do
    datetime = Timex.now() |> Timex.shift(minutes: -5)

    unfetched_udts =
      from(u in UDT,
        where:
          u.type == :native and u.eth_type == :erc721 and
            (is_nil(u.name) or is_nil(u.symbol)) and u.updated_at < ^datetime,
        limit: 50,
        order_by: [desc: u.id]
      )
      |> Repo.all()

    unfetched_udts_hashes = unfetched_udts |> Enum.map(& &1.contract_address_hash)

    {:ok, return} = MetadataRetriever.get_functions_of(unfetched_udts_hashes)

    need_update_list =
      Enum.zip(unfetched_udts, return)
      |> Enum.map(fn {u, r} ->
        if u.contract_address_hash == r.contract_address_hash do
          Map.from_struct(u)
          |> Map.merge(r)
          |> Map.delete(:__meta__)
        else
          Map.from_struct(u)
          |> Map.delete(:__meta__)
        end
      end)

    Import.insert_changes_list(
      need_update_list |> Enum.map(fn udt -> Map.delete(udt, :contract_address_hash) end),
      for: UDT,
      timestamps: import_timestamps(),
      on_conflict: {:replace, [:name, :symbol, :updated_at]},
      conflict_target: :id
    )
  end
end
