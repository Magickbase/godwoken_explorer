defmodule GodwokenIndexer.Account.Worker do
  use GenServer

  alias GodwokenExplorer.Account
  alias GodwokenRPC.HTTP
  alias GodwokenRPC.Account.{FetchedScript, FetchedScriptHash, FetchedNonce}

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: AccountWorker)
  end

  def init(state) do
    GenServer.cast(AccountWorker, {:account, [0, 1]})

    {:ok, state}
  end

  def trigger_account(account_ids) do
    GenServer.cast(AccountWorker, {:account, account_ids})
  end

  def handle_cast({:account, account_ids}, state) do
    account_ids
    |> Enum.each(fn account_id ->
      nonce = fetch_nonce(account_id)
      script_hash = fetch_script_hash(account_id)
      script = fetch_script(script_hash)
      type = switch_account_type(script["code_hash"], script["args"])
      eth_address = account_id_to_eth_adress(account_id, false)

      Account.create_or_update_account(%{
        id: account_id,
        script: script,
        script_hash: script_hash,
        type: type,
        nonce: nonce,
        eth_address: "0x" <> eth_address
      })
    end)

    {:noreply, [state]}
  end

  defp switch_account_type(code_hash, args) do
    polyjuice_code_hash = Application.get_env(:godwoken_explorer, :polyjuice_validator_code_hash)
    layer2_lock_code_hash = Application.get_env(:godwoken_explorer, :layer2_lock_code_hash)
    udt_code_hash = Application.get_env(:godwoken_explorer, :udt_code_hash)
    meta_contract_code_hash = Application.get_env(:godwoken_explorer, :meta_contract_code_hash)

    case code_hash do
      ^meta_contract_code_hash -> :meta_contract
      ^udt_code_hash -> :udt
      ^polyjuice_code_hash when byte_size(args) == 10 -> :polyjuice_root
      ^polyjuice_code_hash -> :polyjuice_contract
      ^layer2_lock_code_hash -> :user
      _ -> :unkonw
    end
  end

  defp fetch_script_hash(account_id) do
    options = Application.get_env(:godwoken_explorer, :json_rpc_named_arguments)

    case FetchedScriptHash.request(%{account_id: account_id})
         |> HTTP.json_rpc(options) do
      {:ok, script_hash} -> script_hash
      {:error, _error} -> nil
    end
  end

  defp fetch_script(script_hash) do
    options = Application.get_env(:godwoken_explorer, :json_rpc_named_arguments)

    case FetchedScript.request(%{script_hash: script_hash})
         |> HTTP.json_rpc(options) do
      {:ok, script} -> script
      {:error, _error} -> nil
    end
  end

  defp fetch_nonce(account_id) do
    options = Application.get_env(:godwoken_explorer, :json_rpc_named_arguments)

    case FetchedNonce.request(%{account_id: account_id})
         |> HTTP.json_rpc(options) do
      {:ok, nonce} -> nonce
      {:error, _error} -> nil
    end
  end

  # ethabi default is false.When use in evm set to true
  defp account_id_to_eth_adress(account_id, ethabi) do
    tail_binary_part = List.duplicate(0, 16) |> :binary.list_to_bin
    head_binary_part = List.duplicate(0, 12) |> :binary.list_to_bin
    if ethabi do
      (head_binary_part <> <<account_id::32-little>> <> tail_binary_part) |> Base.encode16(case: :lower)
    else
      <<account_id::32-little>> <> tail_binary_part |> Base.encode16(case: :lower)
    end
  end
end
