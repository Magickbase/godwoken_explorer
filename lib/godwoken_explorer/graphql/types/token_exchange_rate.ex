defmodule GodwokenExplorer.Graphql.Types.TokenExchangeRate do
  use Absinthe.Schema.Notation
  # alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers

  object :token_exchange_rate do
    field(:symbol, :string, description: "Token symbol name.")
    field(:exchange_rate, :decimal, description: "Token exchange rate.")
    field(:timestamp, :integer, description: "Token last fetch timestamp(millisecond).")
  end

  input_object :sync_fetch_by_symbol_input do
    field(:symbol, non_null(:string))
  end
end
