defmodule GodwokenExplorer.Graphql.Types.TokenExchangeRate do
  use Absinthe.Schema.Notation
  # alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers

  object :token_exchange_rate_mutations do
    @desc """
    Trigger token exchange rate update by symbol name like `ckb`, `btc` or `eth` etc.
    And returning the previous exchange rate value.
    The first time trigger will return `0`.
    """
    # field :sync_fetch_by_symbol, :token_exchange_rate do
    #   arg(:input, non_null(:sync_fetch_by_symbol_input))
    #   resolve(&Resolvers.TokenExchangeRate.sync_fetch_by_symbol/3)
    # end
  end

  object :token_exchange_rate do
    field :symbol, :string, description: "Token symbol name."
    field :exchange_rate, :decimal, description: "Token exchange rate."
    field :timestamp, :integer, description: "Token last fetch timestamp(millisecond)."
  end

  input_object :sync_fetch_by_symbol_input do
    field :symbol, non_null(:string)
  end
end
