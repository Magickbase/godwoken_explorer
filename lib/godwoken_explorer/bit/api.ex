defmodule GodwokenExplorer.Bit.API do
  use Tesla, only: [:get, :post], docs: false
  require Logger

  alias GodwokenExplorer.Chain.Hash.Address

  plug(Tesla.Middleware.BaseUrl, base_url())
  plug(Tesla.Middleware.JSON)

  def batch_fetch_aliases_by_addresses(addresses) do
    addresses =
      addresses
      |> Enum.filter(fn address ->
        Address.cast(address) != :error
      end)

    batch_key_info =
      addresses
      |> Enum.map(fn address ->
        %{
          type: "blockchain",
          key_info: %{
            # 60: ETH, 195: TRX, 9006: BNB, 966: Matic
            coin_type: "60",
            # 1: ETH, 56: BSC, 137: Polygon
            chain_id: "1",
            key: "#{address}"
          }
        }
      end)

    params = %{
      batch_key_info: batch_key_info
    }

    with {:ok, %{body: body}} <- post("/v1/batch/reverse/record", params) do
      returns = process_batch_fetch_reverse_response(body)

      result =
        Enum.zip(addresses, returns)
        |> Enum.map(fn {address, bit_alias} ->
          {:ok, address} = Address.cast(address)
          %{address: address, bit_alias: bit_alias}
        end)

      {:ok, result}
    else
      error ->
        {:error, "error with #{inspect(error)}"}
    end
  end

  defp process_batch_fetch_reverse_response(body) do
    results = body["data"]["list"]

    if results do
      results
      |> Enum.map(fn r ->
        case r do
          %{"account" => _account, "account_alias" => account_alias} ->
            account_alias

          _ ->
            :skip
        end
      end)
      |> Enum.filter(&(&1 != :skip))
    else
      []
    end
  end

  def batch_fetch_addresses_by_aliases(aliases) do
    aliases =
      aliases
      |> Enum.filter(fn a ->
        not is_nil(a) and String.contains?(a, ".bit")
      end)

    params = %{
      "accounts" => aliases
    }

    with {:ok, %{body: body}} <- post("/v1/batch/account/records", params) do
      return = process_batch_fetch_response(body)
      {:ok, return}
    else
      error ->
        Logger.error(fn -> "batch_fetch_addresses_by_aliases with error: #{inspect(error)}" end)
        {:error, "internal_error"}
    end
  end

  defp process_batch_fetch_response(body) do
    results = body["data"]["list"]

    if results do
      results
      |> Enum.map(fn r ->
        with %{"account" => bit_alias, "records" => records} <- r,
             found when not is_nil(found) <-
               Enum.find(records, fn r -> r["key"] == "address.60" end),
             {:ok, address} <- Address.cast(found["value"]) do
          %{bit_alias: bit_alias, address: address}
        else
          _ ->
            :skip
        end
      end)
      |> Enum.filter(&(&1 != :skip))
    else
      []
    end
  end

  def fetch_reverse_record_info(address) do
    params = %{
      type: "blockchain",
      key_info: %{
        # 60: ETH, 195: TRX, 9006: BNB, 966: Matic
        coin_type: "60",
        # 1: ETH, 56: BSC, 137: Polygon
        chain_id: "1",
        key: "#{address}"
      }
    }

    with {:ok, %{body: body}} <- post("/v1/reverse/record", params),
         %{"data" => %{"account_alias" => account_alias}} when not is_nil(account_alias) <- body do
      {:ok, account_alias}
    else
      error ->
        {:error, "error with #{inspect(error)}"}
    end
  end

  def fetch_address_by_alias(bit_alias) do
    params = %{
      account: bit_alias
    }

    with {:ok, %{body: body}} <- post("/v2/account/records", params),
         %{"data" => %{"records" => records}} when not is_nil(records) <- body,
         found when not is_nil(found) <- Enum.find(records, fn r -> r["key"] == "address.60" end),
         {:ok, address} <- Address.cast(found["value"]) do
      {:ok, address}
    else
      error ->
        {:error, "error with #{inspect(error)}"}
    end
  end

  defp base_url do
    Application.fetch_env!(:godwoken_explorer, :bit)[:indexer_url]
  end
end
