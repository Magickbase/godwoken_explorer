defmodule GodwokenExplorerWeb.API.RPC.AccountController do
  use GodwokenExplorerWeb, :controller

  alias GodwokenExplorer.{Chain, AccountUDT}

  def balance(conn, params, template \\ :balance) do
    with {:address_param, {:ok, address_param}} <- fetch_address(params),
         {:format, {:ok, address_hashes}} <- to_address_hashes(address_param) do
      addresses = AccountUDT.get_ckb_balance(address_hashes)
      render(conn, template, %{addresses: addresses})
    else
      {:address_param, :error} ->
        conn
        |> put_status(200)
        |> render(:error, error: "Query parameter 'address' is required")

      {:format, :error} ->
        conn
        |> put_status(200)
        |> render(:error, error: "Invalid address hash")
    end
  end

  def balancemulti(conn, params) do
    balance(conn, params, :balancemulti)
  end

  # def txlist(conn, params) do
  # end

  # def tokentx(conn, params) do
  # end

  defp fetch_address(params) do
    {:address_param, Map.fetch(params, "address")}
  end

  defp to_address_hashes(address_param) when is_binary(address_param) do
    address_param
    |> String.split(",")
    |> Enum.take(20)
    |> to_address_hashes()
  end

  defp to_address_hashes(address_param) when is_list(address_param) do
    address_hashes = address_param_to_address_hashes(address_param)

    if any_errors?(address_hashes) do
      {:format, :error}
    else
      {:format, {:ok, address_hashes}}
    end
  end

  defp address_param_to_address_hashes(address_param) do
    Enum.map(address_param, fn single_address ->
      case Chain.string_to_address_hash(single_address) do
        {:ok, address_hash} -> address_hash
        :error -> :error
      end
    end)
  end

  defp any_errors?(address_hashes) do
    Enum.any?(address_hashes, &(&1 == :error))
  end
end
