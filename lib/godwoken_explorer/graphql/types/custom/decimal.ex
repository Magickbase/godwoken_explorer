defmodule GodwokenExplorer.Graphql.Types.Custom.Decimal do
  use Absinthe.Schema.Notation

  alias Absinthe.Blueprint.Input

  def encode(value), do: Decimal.to_string(value, :normal)

  @spec decode(any) :: {:ok, Decimal.t()} | {:ok, nil} | :error
  def decode(%Input.String{value: value}) when is_binary(value) do
    case Decimal.parse(value) do
      # Decimal V2
      {decimal, ""} -> {:ok, decimal}
      # Decimal V1
      {:ok, decimal} -> {:ok, decimal}
      _ -> :error
    end
  end

  def decode(%Input.Float{value: value}) when is_float(value) do
    decimal = Decimal.from_float(value)
    if Decimal.nan?(decimal), do: :error, else: {:ok, decimal}
  end

  def decode(%Input.Integer{value: value}) when is_integer(value) do
    decimal = Decimal.new(value)
    if Decimal.nan?(decimal), do: :error, else: {:ok, decimal}
  end

  def decode(%Input.Null{}) do
    {:ok, nil}
  end

  def decode(_) do
    :error
  end
end
