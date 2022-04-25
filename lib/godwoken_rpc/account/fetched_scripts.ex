defmodule GodwokenRPC.Account.FetchedScripts do
  alias GodwokenRPC.Account.FetchedScript

  defstruct params_list: [],
            errors: []

  def from_responses(responses, id_to_params) do
    responses
    |> Enum.map(&FetchedScript.from_response(&1, id_to_params))
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
    Enum.map(id_to_params, fn {id, %{script_hash: script_hash, account_id: account_id}} ->
      FetchedScript.request(%{id: id, script_hash: script_hash, account_id: account_id})
    end)
  end
end
