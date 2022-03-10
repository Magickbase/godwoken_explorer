defmodule GodwokenExplorer.Graphql.Types.Custom.Money do
  @moduledoc """
  The Money scalar type allows arbitrary currency values to be passed in and out.
  Requires `{ :money, "~> 1.8" }` package: https://github.com/elixirmoney/money
  """
  use Absinthe.Schema.Notation

  alias Absinthe.Blueprint.Input

  scalar :money, name: "Money" do
    description("""
    The `Money` scalar type represents Money compliant string data, represented as UTF-8
    character sequences. The Money type is most often used to represent currency
    values as human-readable strings.
    """)

    serialize(&Money.to_string/1)
    parse(&decode/1)
  end

  @spec decode(term()) :: {:ok, Money.t()} | {:ok, nil} | :error
  defp decode(%Input.String{value: value}) when is_binary(value) do
    Money.parse(value)
  end

  defp decode(%Input.Float{value: value}) when is_float(value) do
    Money.parse(value)
  end

  defp decode(%Input.Integer{value: value}) when is_integer(value) do
    Money.parse(value)
  end

  defp decode(%Input.Null{}) do
    {:ok, nil}
  end

  defp decode(_) do
    :error
  end
end
