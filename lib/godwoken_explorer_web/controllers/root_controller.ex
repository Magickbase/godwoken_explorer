defmodule GodwokenExplorerWeb.RootController do
  use GodwokenExplorerWeb, :controller

  def index(conn, _params) do
    api = %{
      home_data_url: "#{conn.scheme}://#{conn.host}/api/home",
      block_show_url: "#{conn.scheme}://#{conn.host}/api/blocks/{block_id | block_hash}",
      transaction_show_url: "#{conn.scheme}://#{conn.host}/api/txs/{tx_hash}",
      account_transactions_url: "#{conn.scheme}://#{conn.host}/api/txs?account_id={account_id}&page={page}",
      account_show_url: "#{conn.scheme}://#{conn.host}/api/account/{account_id | short_script_hash | eth_address | layer1_script_hash}",
      search_url: "#{conn.scheme}://#{conn.host}/api/search?keywork={layer1_lock_script | block_hash | tx_hash | account_id | short_script_hash | eth_address | layer1_script_hash | account_id}"
    }
    json(conn, api)
  end
end
