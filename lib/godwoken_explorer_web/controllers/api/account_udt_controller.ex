defmodule GodwokenExplorerWeb.API.AccountUDTController do
  use GodwokenExplorerWeb, :controller

  action_fallback GodwokenExplorerWeb.API.FallbackController

  alias GodwokenExplorer.{Repo, UDT}
  alias GodwokenExplorer.Account.CurrentUDTBalance
  alias GodwokenExplorer.Chain.Exporter.HolderCsv

  def index(conn, %{"udt_id" => udt_id, "export" => "true"}) do
    with %UDT{} <- Repo.get(UDT, udt_id) do
      results = CurrentUDTBalance.sort_holder_list(udt_id, nil)

      HolderCsv.export(results)
      |> Enum.reduce_while(
        conn
        |> put_resp_content_type("application/csv")
        |> put_resp_header(
          "content-disposition",
          "attachment; filename=holders.csv"
        )
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
    else
      _ ->
        {:error, :not_found}
    end
  end

  def index(conn, %{"udt_id" => udt_id}) do
    with %UDT{} <- Repo.get(UDT, udt_id) do
      result =
        CurrentUDTBalance.sort_holder_list(
          udt_id,
          %{page: conn.params["page"] || 1, page_size: conn.assigns.page_size}
        )

      json(
        conn,
        result
      )
    else
      _ ->
        {:error, :not_found}
    end
  end
end
