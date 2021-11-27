defmodule GodwokenIndexer.Account.SyncDepositSupervisor do
  use DynamicSupervisor

  def start_link(_) do
    {:ok, _} = DynamicSupervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    [strategy: :one_for_one]
    |> DynamicSupervisor.init()
  end

  def start_child(account_id) do
    DynamicSupervisor.start_child(
      __MODULE__,
      {GodwokenIndexer.Account.SyncDepositWorker, account_id}
    )
  end
end
