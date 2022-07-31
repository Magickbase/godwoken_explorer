defmodule GodwokenIndexer.Fetcher.UDTInfo do
  use GenServer

  alias GodwokenExplorer.{Repo, UDT}
  alias GodwokenExplorer.Token.MetadataRetriever
  alias GodwokenExplorer.Chain

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{ref: nil}, name: __MODULE__)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  def fetch(address_hash_string) do
    GenServer.call(__MODULE__, {:fetch, address_hash_string})
  end

  @impl true
  def handle_call({:fetch, _address_hash_string}, _from, %{ref: ref} = state)
      when is_reference(ref) do
    {:reply, :ok, state}
  end

  @impl true
  def handle_call({:fetch, address_hash_string}, _from, %{ref: nil} = state) do
    task = do_work(address_hash_string)
    {:reply, :ok, %{state | ref: task.ref}}
  end

  def handle_info({ref, _result}, %{ref: ref} = state) do
    # No need to continue to monitor
    Process.demonitor(ref, [:flush])

    # Do something with the result here...

    {:noreply, %{state | ref: nil}}
  end

  @impl true
  def handle_info({:DOWN, ref, :process, _pid, _reason}, %{ref: ref} = state) do
    {:noreply, %{state | ref: nil}}
  end

  defp do_work(address_hash_string) do
    Task.Supervisor.async_nolink(
      GodwokenIndexer.Fetcher.TaskSupervisor,
      fn ->
        {:ok, address_hash} = Chain.string_to_address_hash(address_hash_string)

        udt_to_update =
          UDT |> Repo.get_by(contract_address_hash: address_hash) |> Repo.preload(:account)

        infos = address_hash_string |> MetadataRetriever.get_functions_of()

        {:ok, _} =
          Chain.update_udt(
            %{
              udt_to_update
              | updated_at: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
            },
            infos
          )
      end,
      restart: :transient
    )
  end
end
