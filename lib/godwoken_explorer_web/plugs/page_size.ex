defmodule GodwokenExplorerWeb.Plugs.PageSize do
  import Plug.Conn

  def init(default), do: default

  def call(%Plug.Conn{params: %{"page_size" => page_size}} = conn, _default) do
    case Integer.parse(page_size) do
      {size, ""} ->
        if size > 50 || size < 0 do
          assign(conn, :page_size, 10)
        else
          assign(conn, :page_size, size)
        end

      _ ->
        assign(conn, :page_size, 10)
    end
  end

  def call(conn, default) do
    assign(conn, :page_size, default)
  end
end
