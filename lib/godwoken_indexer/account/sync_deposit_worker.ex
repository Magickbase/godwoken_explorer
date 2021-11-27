defmodule GodwokenIndexer.Account.SyncDepositWorker do
  use GenServer

  alias GodwokenRPC
  alias GodwokenExplorer.{Account, AccountUDT}

  @auto_timeout 10_000

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  def init(state) do
    {:ok, state}
  end

  def trigger_account(pid) do
    GenServer.cast(pid, :account)
  end

  @spec trigger_sudt_account(any) :: :ok
  def trigger_sudt_account(pid) do
    GenServer.cast(pid, :sudt_account)
  end

  def handle_cast(:account, state) do
    account_ids = state

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

    {:noreply, state, @auto_timeout}
  end

  def handle_cast(:sudt_account, state) do
    udt_and_account_ids = state

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

    {:noreply, state, @auto_timeout}
  end

  def handle_info(:timeout, state) do
    {:stop, :normal, state}
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
