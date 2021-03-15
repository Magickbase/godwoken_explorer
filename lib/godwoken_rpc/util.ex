defmodule GodwokenRPC.Util do
  @stringify_integer_keys ~w(from to block_number number tx_count l2_block nonce aggregator)a
  @stringify_decimal_keys ~w(gas_price fee)a


  def hex_to_number(hex_number) do
    hex_number |> String.slice(2..-1) |> String.to_integer(16)
  end

  def number_to_hex(number) do
    "0x" <> (number |> Integer.to_string(16) |> String.downcase())
  end

  def stringify_and_unix_maps(original_map) do
    original_map
    |> Enum.into(%{}, fn {k, v} ->
      parsed_key =
        case k do
          :transaction_count -> :tx_count
          :from_account_id -> :from
          :to_account_id -> :to
          _ -> k
        end
      parsed_value =
        case parsed_key do
          n when n in @stringify_integer_keys -> Integer.to_string(v)
          d when d in @stringify_decimal_keys -> Decimal.to_string(v)
          :l1_block when not is_nil(v) -> Integer.to_string(v)
          :timestamp -> utc_to_unix(v)
          _ -> v
        end

      {parsed_key, parsed_value}
    end)
  end

  defp utc_to_unix(iso_datetime) do
    iso_datetime |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix()
  end
end
