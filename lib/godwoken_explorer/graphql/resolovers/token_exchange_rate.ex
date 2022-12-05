defmodule GodwokenExplorer.Graphql.Resolvers.TokenExchangeRate do
  alias GodwokenExplorer.Chain.Cache.TokenExchangeRate

  def sync_fetch_by_symbol(_parent, %{input: %{symbol: symbol}} = _args, _resolution) do
    {return, timestamp} = TokenExchangeRate.sync_fetch_by_symbol(symbol)

    return =
      if return == 0 do
        Decimal.new(0)
      else
        return
      end

    {:ok, %{symbol: symbol, exchange_rate: return, timestamp: timestamp}}
  end
end
