defmodule GodwokenIndexer.Account.UpdateInfoWorker do
  use GenServer

  alias GodwokenRPC
  alias GodwokenExplorer.Account

  def start_link(state \\ []) do
    GenServer.start_link(__MODULE__, state, name: InfoWorker)
  end

  def init(state) do
    GenServer.call(AccountWorker, {:account, [0]})

    {:ok, state}
  end

  def sync_trigger_account(account_ids) do
    GenServer.call(InfoWorker, {:account, account_ids})
  end

  def handle_call({:account, account_ids}, _from, state) do
    account_ids
    |> Enum.each(fn account_id ->
      nonce = GodwokenRPC.fetch_nonce(account_id)
      script_hash = GodwokenRPC.fetch_script_hash(%{account_id: account_id})
      short_address = String.slice(script_hash, 0, 42)
      script = GodwokenRPC.fetch_script(script_hash)
      type = switch_account_type(script["code_hash"], script["args"])
      eth_address = account_to_eth_adress(type, script["args"])
      parsed_script = add_name_to_polyjuice_script(type, script)

      Account.create_or_update_account(%{
        id: account_id,
        script: parsed_script,
        script_hash: script_hash,
        short_address: short_address,
        type: type,
        nonce: nonce,
        eth_address: eth_address
      })
    end)

    {:reply, account_ids, state}
  end

  defp switch_account_type(code_hash, args) do
    polyjuice_code_hash = Application.get_env(:godwoken_explorer, :polyjuice_validator_code_hash)
    layer2_lock_code_hash = Application.get_env(:godwoken_explorer, :layer2_lock_code_hash)
    udt_code_hash = Application.get_env(:godwoken_explorer, :udt_code_hash)
    meta_contract_code_hash = Application.get_env(:godwoken_explorer, :meta_contract_code_hash)
    eoa_code_hash = Application.get_env(:godwoken_explorer, :eoa_code_hash)

    case code_hash do
      ^meta_contract_code_hash -> :meta_contract
      ^udt_code_hash -> :udt
      ^polyjuice_code_hash when byte_size(args) == 74 -> :polyjuice_root
      ^polyjuice_code_hash -> :polyjuice_contract
      ^layer2_lock_code_hash -> :user
      ^eoa_code_hash -> :user
      _ -> :unkonw
    end
  end

  defp account_to_eth_adress(type, args) do
    rollup_script_hash = Application.get_env(:godwoken_explorer, :rollup_script_hash)

    if type in [:user, :polyjuice_contract] &&
         args |> String.slice(0, 66) == rollup_script_hash do
      "0x" <> String.slice(args, -40, 40)
    else
      nil
    end
  end

  defp add_name_to_polyjuice_script(type, script) do
    if type in [:polyjuice_contract, :polyjuice_root] do
      script |> Map.merge(%{"name" => "validator"})
    else
      script
    end
  end
end
