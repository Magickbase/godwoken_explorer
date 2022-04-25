defmodule GodwokenRPC.Web3.FetchedCode do
  @moduledoc """
  A single code fetched from `eth_getCode`.
  """

  import GodwokenRPC, only: [quantity_to_integer: 1]

  @doc """
  Converts `response` to code params or annotated error.
  """

  def from_response(%{id: id, result: fetched_code}, id_to_params) when is_map(id_to_params) do
    %{block_quantity: block_quantity, address: address} = Map.fetch!(id_to_params, id)

    {:ok,
     %{
       address: address,
       block_number: quantity_to_integer(block_quantity),
       code: fetched_code
     }}
  end

  def from_response(%{id: id, error: %{code: code, message: message} = error}, id_to_params)
      when is_integer(code) and is_binary(message) and is_map(id_to_params) do
    %{block_quantity: block_quantity, address: address} = Map.fetch!(id_to_params, id)

    annotated_error = Map.put(error, :data, %{block_quantity: block_quantity, address: address})

    {:error, annotated_error}
  end

  def request(%{id: id, block_quantity: block_quantity, address: address}) do
    GodwokenRPC.request(%{id: id, method: "eth_getCode", params: [address, block_quantity]})
  end
end
