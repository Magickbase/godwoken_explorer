defmodule GodwokenExplorerWeb.RootController do
  use GodwokenExplorerWeb, :controller

  def index(conn, _params) do
    api = %{
      home_data_url: "#{conn.scheme}://#{conn.host}/api/home",
      block_show_url: "#{conn.scheme}://#{conn.host}/api/blocks/{block_id}",
      transaction_show_url: "#{conn.scheme}://#{conn.host}/api/txs/{tx_hash}",
      account_transactions_url: "#{conn.scheme}://#{conn.host}/api/txs?account_id={account_id}&page={page}",
      account_show_url: "#{conn.scheme}://#{conn.host}/api/account/{account_id}",
      search_url: "#{conn.scheme}://#{conn.host}/api/search?keywork={block_hash,tx_hash,account_id,lock_script_hash}"
    }
    json(conn, api)
  end
end
