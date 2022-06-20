defmodule GodwokenExplorer.Graphql.Middleware.EIP55 do
  @behaviour Absinthe.Middleware
  def call(resolution, _) do
    resolution
  end

  def call(resolution, config) when is_list(config) do
    arguments = resolution.arguments
    input = arguments[:input]

    if is_nil(input) do
      resolution
    else
      return = eip55check(input, config)

      with_error =
        Enum.any?(return, fn e ->
          case e do
            {:error, _} ->
              true

            _ ->
              false
          end
        end)

      if with_error do
        resolution
        |> Absinthe.Resolution.put_result({:error, "#{inspect(return)}"})
      else
        resolution
      end
    end
  end

  def eip55check(input, config) do
    Enum.reduce(config, [], fn field, acc ->
      case input[field] do
        acc_field when is_bitstring(acc_field) ->
          result = do_eip55check(acc_field)
          [result | acc]

        acc_fields when is_list(acc_fields) ->
          results =
            Enum.map(acc_fields, fn acc_field ->
              do_eip55check(acc_field)
            end)

          results ++ acc

        _ ->
          acc
      end
    end)
  end

  def do_eip55check(field) do
    case validate(field) do
      {:error, resaon} ->
        {:error, "#{resaon}: #{field}"}

      return ->
        return
    end
  end

  @doc """
  Validates a hexadecimal encoded string to see if it conforms to an address.

  ## Error Descriptions

  * `:invalid_characters` - String used non-hexadecimal characters
  * `:invalid_checksum` - Mixed-case string didn't pass [EIP-55 checksum](https://github.com/ethereum/EIPs/blob/master/EIPS/eip-55.md)
  * `:invalid_length` - Addresses are expected to be 40 hex characters long

  ## Example

      iex> Explorer.Chain.Hash.Address.validate("0xc1912fEE45d61C87Cc5EA59DaE31190FFFFf232d")
      {:ok, "0xc1912fEE45d61C87Cc5EA59DaE31190FFFFf232d"}

      iex> Explorer.Chain.Hash.Address.validate("0xc1912fEE45d61C87Cc5EA59DaE31190FFFFf232H")
      {:error, :invalid_characters}
  """
  @spec validate(String.t()) ::
          {:ok, String.t()} | {:error, :invalid_length | :invalid_characters | :invalid_checksum}
  def validate("0x" <> hash) do
    with {:length, true} <- {:length, String.length(hash) == 40},
         {:hex, true} <- {:hex, is_hex?(hash)},
         {:mixed_case, true} <- {:mixed_case, is_mixed_case?(hash)},
         {:checksummed, true} <- {:checksummed, is_checksummed?(hash)} do
      {:ok, "0x" <> hash}
    else
      {:length, false} ->
        {:error, :invalid_length}

      {:hex, false} ->
        {:error, :invalid_characters}

      {:mixed_case, false} ->
        {:ok, "0x" <> hash}

      {:checksummed, false} ->
        {:error, :invalid_checksum}
    end
  end

  @spec is_hex?(String.t()) :: boolean()
  defp is_hex?(hash) do
    case Regex.run(~r|[0-9a-f]{40}|i, hash) do
      nil -> false
      [_] -> true
    end
  end

  @spec is_mixed_case?(String.t()) :: boolean()
  defp is_mixed_case?(hash) do
    upper_check = ~r|[0-9A-F]{40}|
    lower_check = ~r|[0-9a-f]{40}|

    with nil <- Regex.run(upper_check, hash),
         nil <- Regex.run(lower_check, hash) do
      true
    else
      _ -> false
    end
  end

  @spec is_checksummed?(String.t()) :: boolean()
  defp is_checksummed?(original_hash) do
    lowercase_hash = String.downcase(original_hash)
    sha3_hash = ExKeccak.hash_256(lowercase_hash)

    do_checksum_check(sha3_hash, original_hash)
  end

  @spec do_checksum_check(binary(), String.t()) :: boolean()
  defp do_checksum_check(_, ""), do: true

  defp do_checksum_check(sha3_hash, address_hash) do
    <<checksum_digit::integer-size(4), remaining_sha3_hash::bits>> = sha3_hash
    <<current_char::binary-size(1), remaining_address_hash::binary>> = address_hash

    if is_proper_case?(checksum_digit, current_char) do
      do_checksum_check(remaining_sha3_hash, remaining_address_hash)
    else
      false
    end
  end

  @spec is_proper_case?(integer, String.t()) :: boolean()
  defp is_proper_case?(checksum_digit, character) do
    case_map = %{
      "0" => :both,
      "1" => :both,
      "2" => :both,
      "3" => :both,
      "4" => :both,
      "5" => :both,
      "6" => :both,
      "7" => :both,
      "8" => :both,
      "9" => :both,
      "a" => :lower,
      "b" => :lower,
      "c" => :lower,
      "d" => :lower,
      "e" => :lower,
      "f" => :lower,
      "A" => :upper,
      "B" => :upper,
      "C" => :upper,
      "D" => :upper,
      "E" => :upper,
      "F" => :upper
    }

    character_case = Map.get(case_map, character)

    # Digits with checksum digit greater than 7 should be uppercase
    if checksum_digit > 7 do
      character_case in ~w(both upper)a
    else
      character_case in ~w(both lower)a
    end
  end
end
