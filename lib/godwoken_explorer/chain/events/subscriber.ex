defmodule GodwokenExplorer.Chain.Events.Subscriber do
  @moduledoc """
  Subscribes to events related to the Chain context.
  """

  @allowed_broadcast_events ~w(home blocks transactions account_transactions accounts)a

  @allowed_broadcast_types ~w(realtime)a

  @type broadcast_type :: :realtime

  @doc """
  Subscribes the caller process to a specified subset of chain-related events.

  ## Handling An Event

  A subscribed process should handle an event message. The message is in the
  format of a three-element tuple.

  * Element 0 - `:chain_event`
  * Element 1 - event subscribed to
  * Element 2 - event data in list form

  # A new block event in a GenServer
  def handle_info({:chain_event, :blocks, blocks}, state) do
  # Do something with the blocks
  end

  ## Example

  iex> Explorer.Chain.Events.Subscriber.to(:blocks, :realtime)
  :ok
  """
  @spec to(atom(), broadcast_type()) :: :ok
  def to(event_type, broadcast_type)
      when event_type in @allowed_broadcast_events and broadcast_type in @allowed_broadcast_types do
    Registry.register(Registry.ChainEvents, {event_type, broadcast_type}, [])
    :ok
  end
end
