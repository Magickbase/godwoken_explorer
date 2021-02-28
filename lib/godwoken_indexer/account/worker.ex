defmodule GodwokenIndexer.Account.Worker do
  use GenServer

  alias GodwokenExplorer.Account
  alias GodwokenRPC.HTTP
  alias GodwokenRPC.Account.{FetchedScript, FetchedScriptHash}

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: AccountWorker)
  end

  def init(state) do
    GenServer.cast(AccountWorker, {:account, [0,1]})

    {:ok, state}
  end

  def trigger_account(account_ids) do
    GenServer.cast(AccountWorker, {:account, account_ids})
  end

  def handle_cast({:account, account_ids}, state) do
    Account.list_not_exist_accounts(account_ids)
    |> Enum.each(fn account_id ->
      type = switch_account_type(account_id)
      script_hash = fetch_script_hash(account_id)
      script = fetch_script(script_hash)

      Account.create_account(%{
        id: account_id,
        script: script,
        script_hash: script_hash,
        type: type,
        nonce: 0
      })
    end)

    {:noreply, [state]}
  end

  # FIXME: Add other type condition by Script code_hash
  def switch_account_type(account_id) do
    case account_id do
      0 -> :meta_contract
      1 -> :udt
      _ -> :unkonw
    end
  end

  def fetch_script_hash(account_id) do
    options = Application.get_env(:godwoken_explorer, :json_rpc_named_arguments)

    case FetchedScriptHash.request(%{account_id: account_id})
         |> HTTP.json_rpc(options) do
      {:ok, script_hash} -> script_hash
      {:error, _error} -> nil
    end
  end

  def fetch_script(script_hash) do
    options = Application.get_env(:godwoken_explorer, :json_rpc_named_arguments)

    case FetchedScript.request(%{script_hash: script_hash})
         |> HTTP.json_rpc(options) do
      {:ok, script} -> script
      {:error, _error} -> nil
    end
  end
end
