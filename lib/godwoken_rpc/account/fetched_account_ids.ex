defmodule GodwokenRPC.Account.FetchedAccountIDs do
  alias GodwokenRPC.Account.FetchedAccountID

  defstruct params_list: [],
            errors: []

  def from_responses(responses, id_to_params) do
    responses
    |> Enum.map(&FetchedAccountID.from_response(&1, id_to_params))
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
    Enum.map(id_to_params, fn {id, %{script: script, script_hash: script_hash}} ->
      FetchedAccountID.request(%{id: id, script: script, script_hash: script_hash})
    end)
  end
end
