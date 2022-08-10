defmodule GodwokenExplorerWeb.API.SnapshotController do
  use GodwokenExplorerWeb, :controller

  alias GodwokenExplorer.Account.UDTBalance
  alias GodwokenExplorer.Chain.Exporter.TokenHolderCsv

  def index(conn, %{
        "start_block_number" => start_block_number,
        "end_block_number" => end_block_number,
        "token_contract_address_hash" => token_contract_address_hash
      }) do
    results =
      UDTBalance.snapshot_for_token(
        start_block_number,
        end_block_number,
        token_contract_address_hash
      )

    TokenHolderCsv.export(results)
    |> Enum.reduce_while(
      conn
      |> put_resp_content_type("application/csv")
      |> put_resp_header("content-disposition", "attachment; filename=token_holders.csv")
      |> send_chunked(200),
      fn chunk, conn ->
        case Plug.Conn.chunk(
               conn,
               chunk
             ) do
          {:ok, conn} ->
            {:cont, conn}

          {:error, :closed} ->
            {:halt, conn}
        end
      end
    )
  end
end
