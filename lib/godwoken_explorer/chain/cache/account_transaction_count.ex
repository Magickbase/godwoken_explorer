defmodule GodwokenExplorer.Chain.Cache.AccountTransactionCount do
  use GodwokenExplorer.Chain.MapCache,
    name: :account_transaction_count,
    global_ttl: :timer.minutes(3),
    ttl_check_interval: :timer.seconds(30)

  alias GodwokenExplorer.{Transaction, Repo, Account}

  defp handle_fallback(account_id) do
    account = Repo.get(Account, account_id)
    tx_count = Transaction.count_of_account(%{type: account.type, account_id: account.id})
    set(account_id, tx_count)

    {:update, tx_count}
  end
end
