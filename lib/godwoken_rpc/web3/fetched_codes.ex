defmodule GodwokenRPC.Web3.FetchedCodes do
  @moduledoc """
  Code params and errors from a batch request from `eth_getCode`.
  """

  alias GodwokenRPC.Web3.FetchedCode

  defstruct params_list: [],
            errors: []

   @doc """
  `eth_getCode` requests for `id_to_params`.
  """
  def requests(id_to_params) when is_map(id_to_params) do
    Enum.map(id_to_params, fn {id, %{block_quantity: block_quantity, address: address}} ->
      FetchedCode.request(%{id: id, block_quantity: block_quantity, address: address})
    end)
  end

  @doc """
  Converts `responses` to `t/0`.
  """
  def from_responses(responses, id_to_params) do
    responses
    |> Enum.map(&FetchedCode.from_response(&1, id_to_params))
    |> Enum.reduce(
      %__MODULE__{},
      fn
        {:ok, params}, %__MODULE__{params_list: params_list} = acc ->
          %__MODULE__{acc | params_list: [params | params_list]}

        {:error, reason}, %__MODULE__{errors: errors} = acc ->
          %__MODULE__{acc | errors: [reason | errors]}
      end
    )
  end
end
