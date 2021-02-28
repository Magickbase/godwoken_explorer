defmodule GodwokenIndexer.Task.ReservedAccount do
  use Task

  alias GodwokenExplorer.Account
  alias GodwokenRPC.HTTP
  alias GodwokenRPC.Account.{FetchedScript, FetchedScriptHash}

  def start_link(_) do
    Task.start_link(__MODULE__, :run, [])
  end

  def run() do
    [0,1] |> Enum.each(fn account_id ->
      unless Account.account_exist?(account_id) do
        type = switch_account_type(account_id)
        script_hash = fetch_script_hash(account_id)
        script = fetch_script(script_hash)
        Account.create_account(%{id: account_id, script: script, script_hash: script_hash, type: type, nonce: 0})
      end
    end)
  end

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
