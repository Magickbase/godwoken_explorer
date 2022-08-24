defmodule GodwokenExplorer.Graphql.Types.Custom.ChainData do
  use Absinthe.Schema.Notation
  alias GodwokenExplorer.Chain.Data

  scalar :chain_data do
    description("""
    chain data is an unpadded hexadecimal number with 0 or more digits.  Each pair of digits maps directly
    to a byte in the underlying binary representation.  When interpreted as a number, it should be treated as big-endian.
    """)

    serialize(&encode/1)
    parse(&decode/1)
  end

  defp decode(%Absinthe.Blueprint.Input.String{value: value}) do
    case Data.cast(value) do
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

  defp encode(value), do: Data.to_string(value)
end
