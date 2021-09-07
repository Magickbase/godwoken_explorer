defmodule GodwokenRPC.Util do
  alias Blake2.Blake2b

  @stringify_integer_keys ~w(block_number number tx_count l2_block nonce aggregator)a
  @stringify_decimal_keys ~w(gas_price fee)a
  @full_length_size 4
  @offset_size 4

  def parse_le_number(hex_string) do
    hex_string
    |> Base.decode16!(case: :lower)
    |> :binary.decode_unsigned(:little)
  end

  def parse_be_number(hex_string) do
    hex_string
    |> Base.decode16!(case: :lower)
    |> :binary.decode_unsigned(:big)
  end

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

  @spec script_to_hash(nil | maybe_improper_list | map) :: <<_::16, _::_*8>>
  def script_to_hash(script) do
    hash_type = if script["hash_type"] == "data", do: "0x00", else: "0x01"

    values =
      [script["code_hash"], hash_type, serialized_args(String.slice(script["args"], 2..-1))]
      |> Enum.map(fn value -> String.slice(value, 2..-1) end)

    body = values |> Enum.join()
    header_length = @full_length_size + @offset_size * Enum.count(values)

    full_length =
      <<header_length + (body |> String.length() |> Kernel.div(2))::32-little>> |> Base.encode16()

    offset_base = values |> Enum.map(&(&1 |> String.length() |> Kernel.div(2)))

    offsets =
      get_offsets(offset_base)
      |> Enum.map_join(fn value ->
        <<value::32-little>> |> Base.encode16()
      end)

    serialized_script = "#{full_length}#{offsets}#{body}"

    "0x" <>
      Blake2b.hash_hex(
        Base.decode16!(serialized_script, case: :lower),
        "",
        32,
        "",
        "ckb-default-hash"
      )
  end

  defp get_offsets(elm_lengths) do
    header_length = @full_length_size + @offset_size * Enum.count(elm_lengths)

    elm_lengths
    |> Enum.with_index()
    |> Enum.reduce([header_length], fn {_key, index}, acc ->
      if index != 0,
        do: acc ++ [Enum.at(acc, Enum.count(acc) - 1) + Enum.at(elm_lengths, index - 1)],
        else: acc
    end)
  end

  defp serialized_args(args) do
    header = <<args |> String.length() |> Kernel.div(2)::32-little>> |> Base.encode16()
    "0x" <> header <> args
  end

  defp utc_to_unix(iso_datetime) do
    iso_datetime |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix()
  end
end
