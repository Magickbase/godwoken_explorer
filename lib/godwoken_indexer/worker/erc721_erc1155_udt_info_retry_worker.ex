defmodule GodwokenIndexer.Worker.ERC721ERC1155UDTInfoRetryWorker do
  use Oban.Worker,
    queue: :default,
    priority: 3,
    max_attempts: 3,
    unique: [period: 7 * 24 * 60 * 60]

  import GodwokenRPC.Util, only: [import_timestamps: 0]
  alias GodwokenExplorer.Chain.{Import}
  alias GodwokenExplorer.{Repo, UDT}
  alias GodwokenExplorer.Token.MetadataRetriever
  alias GodwokenIndexer.Worker.ERC721ERC1155UDTInfoRetryWorker

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"contract_address_hash" => contract_address_hash}}) do
    do_perform(contract_address_hash)
  end

  @doc """
  The built-in Basic engine doesn't support unique inserts for insert_all and you must use insert/3 for per-job unique support. Alternatively, the SmartEngine in Oban Pro supports bulk unique jobs and automatic batching.
  """
  def new_jobs(contract_address_hashes) when is_list(contract_address_hashes) do
    contract_address_hashes
    |> Enum.map(fn arg ->
      ERC721ERC1155UDTInfoRetryWorker.new(arg)
      |> Oban.insert()
    end)
  end

  def do_perform(contract_address_hash) when is_bitstring(contract_address_hash) do
    fetched_return = MetadataRetriever.get_functions_of(contract_address_hash)

    if is_nil(fetched_return[:name]) or is_nil(fetched_return[:symbol]) do
      {:error,
       "contract address: #{contract_address_hash} fetch name/symbol fail with: #{inspect(fetched_return)}"}
    else
      {:ok, search} = GodwokenExplorer.Chain.Hash.Address.cast(contract_address_hash)
      udt = Repo.get_by!(UDT, contract_address_hash: search)

      udt =
        udt
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
        |> Map.merge(fetched_return)
        |> Map.merge(%{is_fetched: true})

      need_update_list = [udt]

      Import.insert_changes_list(
        need_update_list |> Enum.map(fn udt -> Map.delete(udt, :contract_address_hash) end),
        for: UDT,
        timestamps: import_timestamps(),
        on_conflict: {:replace, [:name, :symbol, :updated_at, :is_fetched]},
        conflict_target: :id
      )
    end
  end
end
