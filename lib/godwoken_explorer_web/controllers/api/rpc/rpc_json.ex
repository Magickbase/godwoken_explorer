defmodule GodwokenExplorerWeb.API.RPC.RPCJSON do
  def render("show.json", %{data: data}) do
    %{
      "status" => "1",
      "message" => "OK",
      "result" => data
    }
  end

  def render("show_value.json", %{data: data}) do
    {value, _} =
      data
      |> Float.parse()

    value
  end

  def render("error.json", %{error: message} = assigns) do
    %{
      "status" => "0",
      "message" => message,
      "result" => Map.get(assigns, :data)
    }
  end
end
