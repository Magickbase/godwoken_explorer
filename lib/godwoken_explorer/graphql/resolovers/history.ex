defmodule GodwokenExplorer.Graphql.Resolvers.History do
  # alias GodwokenExplorer.{WithdrawalHistory, DepositHistory}

  # TODO: show withdrawal_deposit_histories
  def withdrawal_deposit_histories(_parent, _args, _resolution) do
    {:ok, nil}
  end

  # TODO: show udt
  def udt(%{udt_id: _udt_id}, _args, _resolution) do
    {:ok, nil}
  end
end
