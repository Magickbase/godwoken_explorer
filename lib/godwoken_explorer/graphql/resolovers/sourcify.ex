defmodule GodwokenExplorer.Graphql.Resolvers.Sourcify do
  alias GodwokenExplorer.Graphql.Sourcify
  alias GodwokenExplorer.Chain.Hash.Address

  def check_by_addresses(_parent, %{input: input} = _args, _resolution) do
    addresses =
      Map.get(input, :addresses)
      |> Enum.map(fn e -> to_string(e) end)
      |> Enum.join(",")

    case Sourcify.check_by_addresses(addresses) do
      {:error, _} = error ->
        error

      {:ok, return} ->
        return = process_check_by_addresses_result(return)

        {:ok, return}
    end
  end

  defp process_check_by_addresses_result(return) do
    Enum.map(return, fn r ->
      r = r |> Jason.encode!() |> Jason.decode!(keys: :atoms)
      {:ok, address} = Address.cast(r[:address])

      r
      |> Map.put(:chain_ids, r[:chainIds])
      |> Map.put(:address, address)
    end)
  end

  def verify_and_update_from_sourcify(_parent, %{input: %{address: address}} = _args, _resolution) do
    case Sourcify.verify_and_update_from_sourcify(address) do
      {:ok, _} = r ->
        r

      {:error, _} = error ->
        error
    end
  end
end
