defmodule GodwokenIndexer.Account.SyncWorker do
  use GenServer

  alias GodwokenRPC
  alias GodwokenExplorer.{Repo, Account}

  @auto_timeout 5_000

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  def init(state) do
    {:ok, state}
  end

  def get_eth_address_or_id(pid) do
    GenServer.call(pid, :account, :infinity)
  end

  def handle_call(:account, _from, state) do
    account_id = state

    case Repo.get(Account, account_id) do
      nil ->
        nonce = GodwokenRPC.fetch_nonce(account_id)
        script_hash = GodwokenRPC.fetch_script_hash(%{account_id: account_id})
        short_address = String.slice(script_hash, 0, 42)
        script = GodwokenRPC.fetch_script(script_hash)
        type = Account.switch_account_type(script["code_hash"], script["args"])
        eth_address = Account.script_to_eth_adress(type, script["args"])
        parsed_script = Account.add_name_to_polyjuice_script(type, script)

        Account.create_or_update_account!(%{
          id: account_id,
          script: parsed_script,
          script_hash: script_hash,
          short_address: short_address,
          type: type,
          nonce: nonce,
          eth_address: eth_address
        })

        display_value =
          case type do
            :user -> eth_address
            :polyjuice_contract -> short_address
            _ -> account_id
          end

        {:reply, display_value, state, @auto_timeout}

      %Account{eth_address: eth_address, type: :user} when is_binary(eth_address) ->
        {:reply, eth_address, state, @auto_timeout}

      %Account{short_address: short_address, type: :polyjuice_contract} when is_binary(short_address) ->
        {:reply, short_address, state, @auto_timeout}

      _ ->
        {:reply, account_id, state, @auto_timeout}
    end
  end

  def handle_info(:timeout, state) do
    {:stop, :normal, state}
  end

end
