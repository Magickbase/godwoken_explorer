defmodule GodwokenRPC.Block do
  import GodwokenRPC.Util, only: [hex_to_number: 1, timestamp_to_datetime: 1]

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
          "block_producer_id" => aggregator_id,
          "submit_transactions" => %{
            "tx_count" => tx_count
          }
        }
      }) do
    {:ok,
     %{
       "difficulty" => difficulty,
       "extraData" => extra_data,
       "gasLimit" => gas_limit,
       "gasUsed" => gas_used,
       "nonce" => nonce,
       "sha3Uncles" => sha3_uncles,
       "size" => size,
       "stateRoot" => state_root,
       "totalDifficulty" => total_difficulty
     }} = GodwokenRPC.fetch_eth_block_by_hash(hash)

    %{
      hash: hash,
      parent_hash: parent_hash,
      number: hex_to_number(number),
      timestamp: timestamp |> hex_to_number() |> timestamp_to_datetime,
      aggregator_id: hex_to_number(aggregator_id),
      transaction_count: tx_count |> hex_to_number(),
      size: size |> hex_to_number(),
      difficulty: difficulty |> hex_to_number(),
      total_difficulty: total_difficulty |> hex_to_number(),
      gas_limit: gas_limit |> hex_to_number(),
      gas_used: gas_used |> hex_to_number(),
      nonce: nonce,
      sha3_uncles: sha3_uncles,
      state_root: state_root,
      extra_data: extra_data
    }
  end

  def elixir_to_transactions(%{
        "hash" => block_hash,
        "raw" => %{"number" => block_number},
        "transactions" => transactions
      }) do
    transactions
    |> Enum.map(fn t ->
      Map.merge(t, %{"block_hash" => block_hash, "block_number" => hex_to_number(block_number)})
    end)
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
