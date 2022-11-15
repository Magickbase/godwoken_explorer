defmodule GodwokenExplorer.Graphql.Resolvers.TokenExchangeRate do
  alias GodwokenExplorer.Chain.Cache.TokenExchangeRate

  def token_exchange_rate(_parent, %{input: %{symbol: symbol}} = _args, _resolution) do
    return = TokenExchangeRate.fetch_by_symbol(symbol)
    {:ok, %{symbol: symbol, exchange_rate: return}}
  end
end
