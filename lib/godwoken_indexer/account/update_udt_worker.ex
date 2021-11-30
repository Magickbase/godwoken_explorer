defmodule GodwokenIndexer.Account.UpdateUDTWorker do
  use GenServer

  alias GodwokenRPC
  alias GodwokenExplorer.{AccountUDT}

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: UDTWorker)
  end

  def init(state) do
    {:ok, state}
  end

  def sync_trigger_sudt_account(udt_and_account_ids) do
    GenServer.call(UDTWorker, {:sudt_account, udt_and_account_ids})
  end

  def handle_call({:sudt_account, udt_and_account_ids}, _from, state) do
    udt_and_account_ids
    |> Enum.each(fn {udt_id, account_ids} ->
      account_ids
      |> Enum.each(fn account_id ->
        {:ok, balance} = GodwokenRPC.fetch_balance(account_id, udt_id)

        AccountUDT.create_or_update_account_udt(%{
          account_id: account_id,
          udt_id: udt_id,
          balance: balance
        })
      end)
    end)

    {:reply, udt_and_account_ids, state}
  end
end
