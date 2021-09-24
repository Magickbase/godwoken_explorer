defmodule GodwokenIndexer.Account.Worker do
  use GenServer

  import GodwokenRPC.Util, only: [hex_to_number: 1]

  alias GodwokenExplorer.{Account, AccountUDT, Repo}
  alias GodwokenRPC.HTTP
  alias GodwokenRPC
  alias GodwokenRPC.Account.{FetchedScript, FetchedNonce, FetchedBalance}

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(_) do
    GenServer.start_link(__MODULE__, %{}, name: AccountWorker)
  end

  def init(state) do
    GenServer.cast(AccountWorker, {:account, [0]})

    {:ok, state}
  end

  def trigger_account(account_ids) do
    GenServer.cast(AccountWorker, {:account, account_ids})
  end

  def trigger_sudt_account(udt_and_account_ids) do
    GenServer.cast(AccountWorker, {:sudt_account, udt_and_account_ids})
  end

  def handle_cast({:account, account_ids}, state) do
    account_ids
    |> Enum.each(fn account_id ->
      nonce = fetch_nonce(account_id)
      script_hash = GodwokenRPC.fetch_script_hash(%{account_id: account_id})
      short_address = String.slice(script_hash, 0, 42)
      script = fetch_script(script_hash)
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

    {:noreply, [state]}
  end

  @type word() :: String.t()

  def handle_cast({:sudt_account, udt_and_account_ids}, state) do
    udt_and_account_ids
    |> Enum.each(fn {udt_id, account_ids} ->
      account_ids
      |> Enum.each(fn account_id ->
        {:ok, balance} = fetch_balance(account_id, udt_id)

        AccountUDT.create_or_update_account_udt(%{
          account_id: account_id,
          udt_id: udt_id,
          balance: balance
        })
      end)
    end)

    {:noreply, [state]}
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
      {:ok, nonce} -> nonce |> hex_to_number()
      {:error, _error} -> nil
    end
  end

  defp fetch_balance(account_id, udt_id) do
    options = Application.get_env(:godwoken_explorer, :json_rpc_named_arguments)

    short_address =
      case Repo.get(Account, account_id) do
        %Account{short_address: short_address} ->
          short_address

        nil ->
          %{account_id: account_id} |> GodwokenRPC.fetch_script_hash() |> String.slice(0, 42)
      end

    case FetchedBalance.request(%{short_address: short_address, udt_id: udt_id})
         |> HTTP.json_rpc(options) do
      {:ok, balance} -> {:ok, balance |> hex_to_number()}
      {:error, _error} -> {:error, 0}
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
