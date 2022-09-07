defmodule GodwokenIndexer.Worker.ERC721Updater do
  use Oban.Worker, queue: :default

  import GodwokenRPC.Util, only: [import_timestamps: 0]
  alias GodwokenExplorer.Chain.{Import}
  alias GodwokenExplorer.Token.MetadataRetriever

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{chunk_unfetched_udts: chunk_unfetched_udts}}) do
    chunk_unfetched_udts_hashes = chunk_unfetched_udts |> Enum.map(& &1.contract_address_hash)
    {:ok, return} = MetadataRetriever.get_functions_of(chunk_unfetched_udts_hashes)

    need_update_list =
      Enum.zip(chunk_unfetched_udts, return)
      |> Enum.map(fn {u, r} ->
        if u.contract_address_hash == r.contract_address_hash do
          Map.from_struct(u)
          |> Map.merge(r)
        else
          Map.from_struct(u)
        end
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

    Import.insert_changes_list(
      need_update_list |> Enum.map(fn udt -> Map.delete(udt, :contract_address_hash) end),
      for: UDT,
      timestamps: import_timestamps(),
      on_conflict: {:replace, [:name, :symbol, :updated_at]},
      conflict_target: :id
    )

    :ok
  end
end
