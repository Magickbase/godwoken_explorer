defmodule GodwokenRPC.Account.FetchedBalances do
  alias GodwokenRPC.Account.FetchedBalance

  defstruct params_list: [],
            errors: []

  @typedoc """
   * `params_list` - all the balance params from requests that succeeded in the batch.
   * `errors` - all the errors from requests that failed in the batch.
  """
  @type t :: %__MODULE__{params_list: [FetchedBalance.params()], errors: [FetchedBalance.error()]}

  def from_responses(responses, id_to_params) do
    responses
    |> Enum.map(&FetchedBalance.from_response(&1, id_to_params))
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

  def requests(id_to_params) when is_map(id_to_params) do
    Enum.map(id_to_params, fn {id, %{short_address: short_address, udt_id: udt_id}} ->
      FetchedBalance.request(%{id: id, short_address: short_address, udt_id: udt_id})
    end)
  end
end
