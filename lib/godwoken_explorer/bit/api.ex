defmodule GodwokenExplorer.Bit.API do
  require Logger

  use Tesla, only: [:get, :post], docs: false

  plug(Tesla.Middleware.BaseUrl, base_url())
  plug(Tesla.Middleware.JSON)

  def batch_fetch_reverse_record_info(addresses) do
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
      "batch_key_info" => batch_key_info
    }

    with {:ok, %{body: body}} <- post("/v1/batch/reverse/record", params) do
      returns = process_batch_fetch_reverse_response(body)

      result =
        Enum.zip(addresses, returns)
        |> Enum.map(fn {address, bit_alias} -> %{address: address, bit_alias: bit_alias} end)

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

  def batch_fetch_addresses_by_alias(aliases) do
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
        {:error, "error with #{inspect(error)}"}
    end
  end

  defp process_batch_fetch_response(body) do
    results = body["data"]["list"]

    if results do
      results
      |> Enum.map(fn r ->
        case r do
          %{"account" => bit_alias, "records" => records} ->
            found = Enum.find(records, fn r -> r["key"] == "address.eth" end)
            %{bit_alias: bit_alias, address: found["value"]}

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
    url = "#{base_url()}/v1/reverse/record"

    request = %{
      type: "blockchain",
      key_info: %{
        # 60: ETH, 195: TRX, 9006: BNB, 966: Matic
        coin_type: "60",
        # 1: ETH, 56: BSC, 137: Polygon
        chain_id: "1",
        key: "#{address}"
      }
    }

    case HTTPoison.post(url, Jason.encode_to_iodata!(request), [
           {"Content-Type", "application/json"}
         ]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode!(body) do
          %{
            "data" => %{"account" => _, "account_alias" => account_alias},
            "errno" => 0,
            "errmsg" => ""
          } ->
            {:ok, account_alias}

          %{"data" => _data, "errno" => errno, "errmsg" => errmsg} ->
            Logger.error("Fetch #{address} account alias failed.#{errno}: #{errmsg}")
            {:error, nil}
        end

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("Fetch #{address} account alias failed.reason: #{reason}")
        {:error, nil}
    end
  end

  def fetch_address_by_alias(bit_alias) do
    url = "#{base_url()}/v1/account/info"

    request = %{
      account: bit_alias
    }

    case HTTPoison.post(url, Jason.encode_to_iodata!(request), [
           {"Content-Type", "application/json"}
         ]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        case Jason.decode!(body) do
          %{
            "data" => %{"out_point" => _, "account_info" => %{"owner_key" => address}},
            "errno" => 0,
            "errmsg" => ""
          } ->
            {:ok, address}

          %{"data" => _data, "errno" => errno, "errmsg" => errmsg} ->
            Logger.error("Fetch #{bit_alias} address failed.#{errno}: #{errmsg}")
            {:error, nil}
        end

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error("Fetch #{bit_alias} address failed.reason: #{reason}")
        {:error, nil}
    end
  end

  defp base_url do
    Application.fetch_env!(:godwoken_explorer, :bit)[:indexer_url]
  end
end
