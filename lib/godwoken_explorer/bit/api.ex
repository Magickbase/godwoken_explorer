defmodule GodwokenExplorer.Bit.API do
  require Logger

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
