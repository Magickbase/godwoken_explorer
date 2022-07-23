defmodule GodwokenExplorerWeb.API.RPC.AccountView do
  use GodwokenExplorerWeb, :view

  alias GodwokenExplorerWeb.API.RPC.RPCView

  def render("balance.json", %{addresses: [address]}) do
    RPCView.render("show.json", data: address[:balance])
  end

  def render("balance.json", assigns) do
    render("balancemulti.json", assigns)
  end

  def render("balancemulti.json", %{addresses: addresses}) do
    RPCView.render("show.json", data: addresses)
  end

  def render("error.json", assigns) do
    RPCView.render("error.json", assigns)
  end

  def render("txlist.json", %{transactions: transactions}) do
    data = Enum.map(transactions, &prepare_transaction/1)
    RPCView.render("show.json", data: data)
  end

  def render("tokentx.json", %{token_transfers: token_transfers}) do
    data = Enum.map(token_transfers, &prepare_token_transfer/1)
    RPCView.render("show.json", data: data)
  end

  def render("tokenbalance.json", %{token_balance: token_balance}) do
    RPCView.render("show.json", data: to_string(token_balance))
  end

  defp prepare_transaction(transaction) do
    %{
      "blockNumber" => "#{transaction.block_number}",
      "timeStamp" => "#{DateTime.to_unix(transaction.timestamp)}",
      "hash" => "#{transaction.hash}",
      "nonce" => "#{transaction.nonce}",
      "blockHash" => "#{transaction.block_hash}",
      "transactionIndex" => "#{transaction.index}",
      "from" => "#{transaction.from}",
      "to" => "#{transaction.to}",
      "value" => "#{transaction.value}",
      "gas" => "#{transaction.gas_limit}",
      "gasPrice" => "#{transaction.gas_price}",
      "txreceipt_status" => if(transaction.polyjuice_status == :succeed, do: "1", else: "0"),
      "input" => "#{transaction.input}",
      "contractAddress" => "#{transaction.created_contract_address_hash}",
      "gasUsed" => "#{transaction.gas_used}"
    }
  end

  defp prepare_token_transfer(token_transfer) do
    token_transfer
    |> prepare_common_token_transfer()
    |> Map.put_new(:value, to_string(token_transfer.amount))
  end

  defp prepare_common_token_transfer(token_transfer) do
    %{
      "blockNumber" => to_string(token_transfer.block_number),
      "timeStamp" => to_string(DateTime.to_unix(token_transfer.block_timestamp)),
      "hash" => to_string(token_transfer.transaction_hash),
      "nonce" => to_string(token_transfer.transaction_nonce),
      "blockHash" => to_string(token_transfer.block_hash),
      "from" => to_string(token_transfer.from_address_hash),
      "contractAddress" => to_string(token_transfer.token_contract_address_hash),
      "to" => to_string(token_transfer.to_address_hash),
      "logIndex" => to_string(token_transfer.token_log_index),
      "tokenName" => token_transfer.token_name,
      "tokenSymbol" => token_transfer.token_symbol,
      "tokenDecimal" => to_string(token_transfer.token_decimals),
      "transactionIndex" => to_string(token_transfer.transaction_index),
      "gas" => to_string(token_transfer.transaction_gas),
      "gasPrice" => to_string(token_transfer.transaction_gas_price),
      "gasUsed" => to_string(token_transfer.transaction_gas_used),
      "input" => to_string(token_transfer.transaction_input)
    }
  end
end
