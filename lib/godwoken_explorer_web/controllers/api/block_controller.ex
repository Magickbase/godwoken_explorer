defmodule GodwokenExplorerWeb.API.BlockController do
  use GodwokenExplorerWeb, :controller
  alias GodwokenExplorer.Block

  def index(conn, _params) do
    blocks = Block.latest_10_records()

    json(
      conn,
      %{
        blocks: blocks
      }
    )
  end
end
