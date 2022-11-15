defmodule GodwokenExplorer.Graphql.Types.TokenExchangeRate do
  use Absinthe.Schema.Notation
  alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers

  object :token_exchange_rate_mutations do
    @desc """
    Trigger token exchange rate update by symbol name like `ckb`, `btc` or `eth` etc.
    And returning the previous exchange rate value.
    The first time trigger will return `0`.
    """
    field :token_exchange_rate, :token_exchange_rate do
      arg(:input, non_null(:token_exchange_rate_input))
      resolve(&Resolvers.TokenExchangeRate.token_exchange_rate/3)
    end
  end

  object :token_exchange_rate do
    field :symbol, :string, description: "Token symbol."
    field :exchange_rate, :decimal, description: "Token exchange rate."
  end

  input_object :token_exchange_rate_input do
    field :symbol, non_null(:string)
  end
end
