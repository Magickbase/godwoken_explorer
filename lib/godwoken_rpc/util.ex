defmodule GodwokenRPC.Util do
  alias Blake2.Blake2b
  alias GodwokenExplorer.UDT

  @type decimal() :: Decimal.t()
  @stringify_ckb_decimal_keys ~w(gas_price fee value)a
  @utc_unix_keys ~w(timestamp inserted_at)a
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
          :inserted_at -> :timestamp
          _ -> k
        end

      parsed_value =
        case parsed_key do
          d when d in @stringify_ckb_decimal_keys ->
            balance_to_view(v, 8)

          u when u in @utc_unix_keys ->
            utc_to_unix(v)

          :transfer_value ->
            balance_to_view(v, UDT.get_decimal(original_map.to_account_id))

          _ ->
            v
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

  def timestamp_to_datetime(timestamp) do
    timestamp
    |> DateTime.from_unix!(:millisecond)
  end

  def parse_polyjuice_args(hex_string) do
    is_create = hex_string |> String.slice(14, 2) == "03"

    gas_limit =
      hex_string
      |> String.slice(16, 16)
      |> parse_le_number()

    gas_price =
      hex_string
      |> String.slice(32, 32)
      |> parse_le_number()

    value =
      hex_string
      |> String.slice(64, 32)
      |> parse_le_number()

    input_size =
      hex_string
      |> String.slice(96, 8)
      |> parse_le_number()

    input = hex_string |> String.slice(104..-1)
    [is_create, gas_limit, gas_price, value, input_size, "0x" <> input]
  end

  def transform_hash_type(hash_type) do
    case hash_type do
      "00" -> "data"
      _ -> "type"
    end
  end

  @spec balance_to_view(decimal, integer) :: String.t()
  def balance_to_view(balance, decimal) do
    if balance == "" or is_nil(balance) do
      ""
    else
      balance |> Decimal.div(Integer.pow(10, decimal)) |> Decimal.to_string(:normal)
    end
  end

  defp serialized_args(args) do
    header = <<args |> String.length() |> Kernel.div(2)::32-little>> |> Base.encode16()
    "0x" <> header <> args
  end

  def utc_to_unix(iso_datetime) do
    iso_datetime |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix()
  end

  def import_timestamps do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    %{inserted_at: now, updated_at: now}
  end
end
