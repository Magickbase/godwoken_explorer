defmodule GodwokenExplorer.Graphql.Resolvers.UDT do
  alias GodwokenExplorer.{UDT}

  # TODO: show account
  def account(%UDT{} = _parent, _args, _resolution) do
    {:ok, nil}
  end

  # TODO: show bridge_account
  def bridge_account(%UDT{} = _parent, _args, _resolution) do
    {:ok, nil}
  end

  # TODO: show udt
  def udt(_parent, _args, _resolution) do
    {:ok, nil}
  end

  # TODO: show udts
  def udts(_parent, _args, _resolution) do
    {:ok, nil}
  end
end
