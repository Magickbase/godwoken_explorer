defmodule GodwokenRPC.Transaction do
  import GodwokenRPC.Util, only: [hex_to_number: 1]

  def elixir_to_params(
        %{
          "block_hash" => block_hash,
          "block_number" => block_number,
          "raw" => %{
            "from_id" => from_account_id,
            "to_id" => to_account_id,
            "nonce" => nonce,
            "args" => args
          },
          "hash" => hash
        }
      ) when to_account_id == "0x0" do
        %{
          type: :polyjuice_creator,
          hash: hash,
          block_hash: block_hash,
          block_number: block_number,
          nonce: hex_to_number(nonce),
          args: args,
          from_account_id: hex_to_number(from_account_id),
          to_account_id: hex_to_number(to_account_id),
        }
  end

  def elixir_to_params(
        %{
          "block_hash" => block_hash,
          "block_number" => block_number,
          "raw" => %{
            "from_id" => from_account_id,
            "to_id" => udt_id,
            "nonce" => nonce,
            "args" => args
          },
          "hash" => hash
        }
      ) do
        [to_account_id, amount, fee] = parse_sudt_args(args)
        %{
          type: :sudt,
          hash: hash,
          block_hash: block_hash,
          block_number: block_number,
          nonce: hex_to_number(nonce),
          args: args,
          from_account_id: hex_to_number(from_account_id),
          to_account_id: to_account_id,
          udt_id: hex_to_number(udt_id),
          amount: amount,
          fee: fee
        }
  end

  defp parse_sudt_args(hex_string) do
    to_account_id = hex_string |> String.slice(10, 8) |> Base.decode16!() |> :binary.decode_unsigned(:little)
    amount = hex_string |> String.slice(18, 32) |> Base.decode16!() |> :binary.decode_unsigned(:little)
    fee = hex_string |> String.slice(50, 32) |> Base.decode16!() |> :binary.decode_unsigned(:little)

    [to_account_id, amount, fee]
  end
end
