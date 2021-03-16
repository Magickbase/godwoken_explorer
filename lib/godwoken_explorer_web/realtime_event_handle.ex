defmodule GodwokenExplorerWeb.RealtimeEventHandler do
  @moduledoc """
  Subscribing process for broadcast events from realtime.
  """

  use GenServer

  alias GodwokenExplorerWeb.Notifier
  alias GodwokenExplorer.Chain.Events.Subscriber

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @impl true
  def init([]) do
    Subscriber.to(:home, :realtime)
    Subscriber.to(:blocks, :realtime)
    Subscriber.to(:transactions, :realtime)
    Subscriber.to(:account_transactions, :realtime)
    Subscriber.to(:accounts, :realtime)

    {:ok, []}
  end

  @impl true
  def handle_info(event, state) do
    Notifier.handle_event(event)
    {:noreply, state}
  end
end
