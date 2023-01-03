defmodule GodwokenExplorer.Graphql.Resolvers.Address do
  alias GodwokenExplorer.{Address, Repo}

  def address(_parent, %{input: input} = _args, _resolution) do
    address = Map.get(input, :address)

    case Repo.get(Address, address) do
      %Address{} = address ->
        Address.async_update_info(address)
        {:ok, address}

      nil ->
        {:ok, nil}
    end
  end
end
