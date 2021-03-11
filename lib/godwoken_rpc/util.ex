defmodule GodwokenRPC.Util do
  @stringify_integer_keys ~w(from to block_number number tx_count l2_block nonce aggregator)a
  @stringify_decimal_keys ~w(gas_price fee)a


  def hex_to_number(hex_number) do
    hex_number |> String.slice(2..-1) |> String.to_integer(16)
  end

  def number_to_hex(number) do
    "0x" <> (number |> Integer.to_string(16) |> String.downcase())
  end

  @spec utc_to_unix(NaiveDateTime.t()) :: integer
  def utc_to_unix(iso_datetime) do
    iso_datetime |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix()
  end

  def stringify_and_unix_maps(original_map) do
    original_map
    |> Enum.into(%{}, fn {k, v} ->
      new_k =
        case k do
          :transaction_count -> :tx_count
          :from_account_id -> :from
          :to_account_id -> :to
          _ -> k
        end
      new_v =
        case new_k do
          n when n in @stringify_integer_keys -> v |> Integer.to_string()
          d when d in @stringify_decimal_keys -> v |> Decimal.to_string()
          :l1_block when is_nil(v) -> nil
          :l1_block when not is_nil(v) -> v |> Integer.to_string()
          :timestamp -> utc_to_unix(v)
          _ -> v
        end

      {new_k, new_v}
    end)
  end
end
