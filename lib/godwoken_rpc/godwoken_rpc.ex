defmodule GodwokenRPC do
  alias GodwokenRPC.{Blocks, Block, HTTP}

  def request(%{method: method, params: params} = map)
      when is_binary(method) and is_list(params) do
    Map.put(map, :jsonrpc, "2.0")
  end

  def fetch_blocks_by_range(_first.._last = range) do
    range
    |> Enum.map(fn number -> %{number: number} end)
    |> fetch_blocks_by_params(&Block.ByNumber.request/1)
  end

  defp fetch_blocks_by_params(params, request)
       when is_list(params) and is_function(request, 1) do
    id_to_params = id_to_params(params)
    options = Application.get_env(:godwoken_explorer, :json_rpc_named_arguments)

    with {:ok, responses} <-
           id_to_params
           |> Blocks.requests(request)
           |> HTTP.json_rpc(options) do
      {:ok, Blocks.from_responses(responses, id_to_params)}
    end
  end

  def id_to_params(params_list) do
    params_list
    |> Stream.with_index()
    |> Enum.into(%{}, fn {params, id} -> {id, params} end)
  end

end
