defmodule GodwokenExplorer.Graphql.Types.Custom.HashFull do
  use Absinthe.Schema.Notation
  alias GodwokenExplorer.Chain.Hash
  alias GodwokenExplorer.Chain.Hash.Full

  scalar :hash_full do
    description("""
    A 32-byte [KECCAK-256](https://en.wikipedia.org/wiki/SHA-3) hash.
    """)

    serialize(&encode/1)
    parse(&decode/1)
  end

  defp decode(%Absinthe.Blueprint.Input.String{value: value}) do
    case Full.cast(value) do
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

  defp encode(%Hash{} = value) do
    Hash.to_string(value)
  end

  defp encode(value) when is_binary(value) do
    data = %Hash{bytes: value, byte_count: 32}
    Hash.to_string(data)
  end
end
