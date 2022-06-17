defmodule GodwokenExplorer.Graphql.Types.Custom.HashAddress do
  use Absinthe.Schema.Notation
  alias GodwokenExplorer.Chain.Hash
  alias GodwokenExplorer.Chain.Hash.Address

  scalar :hashaddress do
    description("""
    The address (40 (hex) characters / 160 bits / 20 bytes) is derived from the public key (128 (hex) characters /
    512 bits / 64 bytes) which is derived from the private key (64 (hex) characters / 256 bits / 32 bytes).

    The address is actually the last 40 characters of the keccak-256 hash of the public key with `0x` appended.
    """)

    serialize(&encode/1)
    parse(&decode/1)
  end

  defp decode(%Absinthe.Blueprint.Input.String{value: value}) do
    case Address.cast(value) do
      {:ok, result} -> {:ok, result}
      _ -> :error
    end
  end

  defp decode(%Absinthe.Blueprint.Input.Null{}) do
    {:ok, nil}
  end

  defp decode(_) do
    :error
  end

  defp encode(value), do: Hash.to_string(value)
end
