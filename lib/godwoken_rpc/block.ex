defmodule GodwokenRPC.Block do
  import GodwokenRPC.Util, only: [hex_to_number: 1, parse_block_producer: 1]

  require Logger

  @eth_addr_reg_id Application.get_env(:godwoken_explorer, :eth_addr_reg_id)

  def from_response(%{id: id, result: nil}, id_to_params) when is_map(id_to_params) do
    params = Map.fetch!(id_to_params, id)

    {:error, %{code: 404, message: "Not Found", data: params}}
  end

  def from_response(%{id: id, result: block}, id_to_params) when is_map(id_to_params) do
    true = Map.has_key?(id_to_params, id)

    {:ok, block}
  end

  def from_response(%{id: id, error: error}, id_to_params) when is_map(id_to_params) do
    params = Map.fetch!(id_to_params, id)
    annotated_error = Map.put(error, :data, params)

    {:error, annotated_error}
  end

  def elixir_to_params(%{
        "hash" => hash,
        "raw" => %{
          "parent_block_hash" => parent_hash,
          "number" => number,
          "timestamp" => timestamp,
          "block_producer" => block_producer,
          "submit_transactions" => %{
            "tx_count" => tx_count
          }
        }
      }) do
    {registry_id, producer_address} =
      block_producer |> String.slice(2..-1) |> parse_block_producer()

    {:ok,
     %{
       "gasLimit" => gas_limit,
       "gasUsed" => gas_used,
       "size" => size,
       "logsBloom" => logs_bloom
     }} = GodwokenRPC.fetch_eth_block_by_hash(hash)

    %{
      hash: hash,
      parent_hash: parent_hash,
      number: hex_to_number(number),
      timestamp:
        timestamp |> hex_to_number() |> Kernel.*(1000) |> DateTime.from_unix!(:microsecond),
      registry_id: registry_id,
      producer_address: producer_address,
      transaction_count: tx_count |> hex_to_number(),
      size: size |> hex_to_number(),
      logs_bloom: logs_bloom,
      status: :committed,
      gas_limit: gas_limit |> hex_to_number(),
      gas_used: gas_used |> hex_to_number()
    }
  end

  def elixir_to_transactions(%{
        "hash" => block_hash,
        "raw" => %{"number" => block_number},
        "transactions" => transactions
      })
      when transactions != [] do
    case GodwokenRPC.fetch_eth_block_by_hash(block_hash) do
      {:ok,
       %{
         "transactions" => []
       }} ->
        transactions
        |> Enum.map(fn t ->
          Map.merge(t, %{
            "block_hash" => block_hash,
            "block_number" => hex_to_number(block_number),
            "eth_hash" => nil
          })
        end)

      {:ok,
       %{
         "transactions" => eth_transactions
       }} ->
        if length(eth_transactions) != length(transactions) do
          {other_type_txs, polyjuice_txs} =
            transactions
            |> Enum.split_with(fn t ->
              t["raw"]["to_id"] in ["0x0", @eth_addr_reg_id]
            end)

          parsed_polyjuice_txs =
            polyjuice_txs
            |> Enum.with_index()
            |> Enum.map(fn {t, index} ->
              Map.merge(t, %{
                "block_hash" => block_hash,
                "block_number" => hex_to_number(block_number),
                "eth_hash" => eth_transactions |> Enum.at(index)
              })
            end)

          parsed_other_type_txs =
            other_type_txs
            |> Enum.map(fn t ->
              Map.merge(t, %{
                "block_hash" => block_hash,
                "block_number" => hex_to_number(block_number),
                "eth_hash" => nil
              })
            end)

          parsed_other_type_txs ++ parsed_polyjuice_txs
        else
          transactions
          |> Enum.with_index()
          |> Enum.map(fn {t, index} ->
            Map.merge(t, %{
              "block_hash" => block_hash,
              "block_number" => hex_to_number(block_number),
              "eth_hash" => eth_transactions |> Enum.at(index)
            })
          end)
        end
    end
  end

  def elixir_to_transactions(_), do: []

  def elixir_to_withdrawal_requests(%{
        "hash" => block_hash,
        "raw" => %{"number" => block_number},
        "withdrawal_requests" => withdrawal_requests
      })
      when length(withdrawal_requests) != 0 do
    withdrawal_requests
    |> Enum.map(fn t ->
      Map.merge(t, %{"block_hash" => block_hash, "block_number" => hex_to_number(block_number)})
    end)
  end

  def elixir_to_withdrawal_requests(_), do: []
end
