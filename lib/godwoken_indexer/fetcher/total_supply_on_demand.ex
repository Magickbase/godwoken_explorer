defmodule GodwokenIndexer.Fetcher.TotalSupplyOnDemand do
  use GenServer

  alias GodwokenExplorer.{Repo, UDT}
  alias GodwokenExplorer.Token.MetadataRetriever
  alias GodwokenExplorer.Chain

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: TotalSupplyOnDemand)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  def fetch(address_hash_string) do
    GenServer.cast(TotalSupplyOnDemand, {:fetch, address_hash_string})
  end

  @impl true
  def handle_cast({:fetch, address_hash_string}, state) do
    {:ok, address_hash} = Chain.string_to_address_hash(address_hash_string)

    udt_to_update =
      UDT |> Repo.get_by(contract_address_hash: address_hash) |> Repo.preload(:account)

    %{total_supply: total_supply} = address_hash_string |> MetadataRetriever.get_total_supply_of()

    {:ok, _} =
      Chain.update_udt(
        %{
          udt_to_update
          | updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
        },
        %{supply: total_supply}
      )

    {:noreply, [state]}
  end
end
