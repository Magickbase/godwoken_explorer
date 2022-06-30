defmodule GodwokenExplorerWeb.API.TransferController do
  use GodwokenExplorerWeb, :controller

  alias GodwokenExplorer.{Account, Chain, Repo, TokenTransfer}

  alias GodwokenExplorer.Chain.Exporter.{TransactionTransferCsv, TransferCsv}

  action_fallback(GodwokenExplorerWeb.API.FallbackController)

  def index(conn, %{"eth_address" => "0x" <> _, "udt_address" => "0x" <> _} = params) do
    with %Account{eth_address: eth_address} <-
           Account |> Repo.get_by(eth_address: String.downcase(params["eth_address"])),
         %Account{eth_address: udt_address} <-
           Repo.get_by(Account, eth_address: String.downcase(params["udt_address"])) do
      results =
        TokenTransfer.list(
          %{eth_address: eth_address, udt_address: udt_address},
          %{
            page: conn.params["page"] || 1,
            page_size: conn.assigns.page_size
          }
        )

      json(conn, results)
    else
      _ ->
        {:error, :not_found}
    end
  end

  def index(conn, %{"eth_address" => "0x" <> _, "export" => "true"} = params) do
    with {:ok, address_hash} <- Chain.string_to_address_hash(params["eth_address"]),
         {:address, :ok} <- {:address, Chain.check_address_exists(address_hash)} do
      results = TokenTransfer.list(%{eth_address: address_hash}, nil)

      TransferCsv.export(results)
      |> Enum.reduce_while(
        conn
        |> put_resp_content_type("application/csv")
        |> put_resp_header("content-disposition", "attachment; filename=token_transfers.csv")
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

  def index(conn, %{"eth_address" => "0x" <> _} = params) do
    with {:ok, address_hash} <- Chain.string_to_address_hash(params["eth_address"]),
         {:address, :ok} <- {:address, Chain.check_address_exists(address_hash)} do
      results =
        TokenTransfer.list(%{eth_address: address_hash}, %{
          page: conn.params["page"] || 1,
          page_size: conn.assigns.page_size
        })

      json(conn, results)
    else
      _ ->
        results =
          TokenTransfer.list(%{eth_address: String.downcase(params["eth_address"])}, %{
            page: conn.params["page"] || 1,
            page_size: conn.assigns.page_size
          })

        json(conn, results)
    end
  end

  def index(conn, %{"udt_address" => "0x" <> _, "export" => "true"} = params) do
    with {:ok, address_hash} <- Chain.string_to_address_hash(params["udt_address"]),
         {:address, :ok} <- {:address, Chain.check_address_exists(address_hash)} do
      results = TokenTransfer.list(%{udt_address: address_hash}, nil)

      TransferCsv.export(results)
      |> Enum.reduce_while(
        conn
        |> put_resp_content_type("application/csv")
        |> put_resp_header("content-disposition", "attachment; filename=token_transfers.csv")
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

  def index(conn, %{"udt_address" => "0x" <> _} = params) do
    with {:ok, address_hash} <- Chain.string_to_address_hash(params["udt_address"]),
         {:address, :ok} <- {:address, Chain.check_address_exists(address_hash)} do
      results =
        TokenTransfer.list(%{udt_address: address_hash}, %{
          page: conn.params["page"] || 1,
          page_size: conn.assigns.page_size
        })

      json(conn, results)
    else
      _ ->
        {:error, :not_found}
    end
  end

  def index(conn, %{"tx_hash" => "0x" <> _, "export" => "true"} = params) do
    TransactionTransferCsv.export(params["tx_hash"])
    |> Enum.reduce_while(
      conn
      |> put_resp_content_type("application/csv")
      |> put_resp_header("content-disposition", "attachment; filename=token_transfers.csv")
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

  def index(conn, %{"tx_hash" => "0x" <> _} = params) do
    results =
      TokenTransfer.list(%{tx_hash: params["tx_hash"]}, %{
        page: conn.params["page"] || 1,
        page_size: conn.assigns.page_size
      })

    json(conn, results)
  end

  def index(_conn, _) do
    {:error, :not_found}
  end
end
