defmodule GodwokenRPC.Transaction do
  import GodwokenRPC.Util, only: [hex_to_number: 1]

  def elixir_to_params(
        %{
          "block_hash" => block_hash,
          "block_number" => block_number,
          "raw" => %{
            "from_id" => from_account_id,
            "to_id" => sudt_id,
            "nonce" => nonce,
            "args" => args
          },
          "hash" => hash
        }
      ) do
        %{
          hash: hash,
          block_hash: block_hash,
          block_number: block_number,
          nonce: hex_to_number(nonce),
          args: args,
          from_account_id: hex_to_number(from_account_id)
        }
  end
end
