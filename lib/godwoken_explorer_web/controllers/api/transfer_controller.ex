defmodule GodwokenExplorerWeb.API.TransferController do
  use GodwokenExplorerWeb, :controller

  alias GodwokenExplorer.{Account, Repo, TokenTransfer}

  action_fallback GodwokenExplorerWeb.API.FallbackController

  def index(conn, %{"eth_address" => "0x" <> _, "udt_address" => "0x" <> _} = params) do
    with %Account{short_address: short_address} <-
           Account |> Repo.get_by(eth_address: String.downcase(params["eth_address"])),
         %Account{short_address: udt_address} <-
           Repo.get_by(Account, eth_address: String.downcase(params["udt_address"])) do
      results =
        TokenTransfer.list(%{eth_address: short_address, udt_address: udt_address}, %{
          page: conn.params["page"] || 1,
          page_size: conn.assigns.page_size
        })

      json(conn, results)
    else
      _ ->
        {:error, :not_found}
    end
  end

  def index(conn, %{"eth_address" => "0x" <> _} = params) do
    with %Account{short_address: short_address} <-
           Account |> Repo.get_by(eth_address: String.downcase(params["eth_address"])) do
      results =
        TokenTransfer.list(%{eth_address: short_address}, %{
          page: conn.params["page"] || 1,
          page_size: conn.assigns.page_size
        })

      json(conn, results)
    else
      _ ->
        {:error, :not_found}
    end
  end

  def index(conn, %{"udt_address" => "0x" <> _} = params) do
    case Repo.get_by(Account, short_address: String.downcase(params["udt_address"])) do
      %Account{short_address: udt_address} ->
        results =
          TokenTransfer.list(%{udt_address: udt_address}, %{
            page: conn.params["page"] || 1,
            page_size: conn.assigns.page_size
          })

        json(conn, results)

      nil ->
        {:error, :not_found}
    end
  end

  def index(conn, %{"tx_hash" => "0x" <> _} = params) do
    results =
      TokenTransfer.list(%{tx_hash: params["tx_hash"]}, %{
        page: conn.params["page"] || 1,
        page_size: conn.assigns.page_size
      })

    json(conn, results)
  end
end
