defmodule GodwokenExplorerWeb.API.TransferControllerTest do
  use GodwokenExplorerWeb.ConnCase

  import GodwokenExplorer.Factory

  import GodwokenRPC.Util,
    only: [
      balance_to_view: 2,
      utc_to_unix: 1
    ]

  setup do
    account = insert(:polyjuice_contract_account)
    udt = insert(:native_udt, contract_address_hash: account.eth_address)
    user = insert(:user)
    to_user = insert(:user)

    block = insert(:block)

    tx =
      insert(:transaction,
        block: block,
        block_number: block.number,
        from_account: user,
        to_account: account,
        index: 1
      )

    polyjuice = insert(:polyjuice, transaction: tx)

    transfer =
      insert(:token_transfer,
        transaction: tx,
        token_contract_address_hash: udt.contract_address_hash,
        from_address_hash: user.eth_address,
        to_address_hash: to_user.eth_address
      )

    %{
      user: user,
      to_user: to_user,
      transfer: transfer,
      udt: udt,
      tx: tx,
      polyjuice: polyjuice,
      block: block
    }
  end

  describe "index" do
    test "when eth address account not exist", %{conn: conn} do
      conn =
        get(
          conn,
          ~p"/api/transfers?eth_address=0x085a61d7164735FC5378E590b5ED1448561e1a48"
        )

      assert json_response(conn, 200) == %{"txs" => [], "page" => 1, "total_count" => 0}
    end

    test "when tx_hash not exist", %{conn: conn} do
      conn =
        get(
          conn,
          ~p"/api/transfers?tx_hash=0x5710b3d039850d5dd44e35949a8e23e519b6f8abc50c9c1932e8cf6f05b40f39"
        )

      assert json_response(conn, 200) ==
               %{"page" => 1, "total_count" => 0, "txs" => []}
    end

    test "query by eth address and udt address", %{
      conn: conn,
      user: user,
      to_user: to_user,
      transfer: transfer,
      udt: udt,
      tx: tx,
      polyjuice: polyjuice,
      block: block
    } do
      conn =
        get(
          conn,
          ~p"/api/transfers?eth_address=#{to_string(user.eth_address)}&udt_address=#{to_string(udt.contract_address_hash)}"
        )

      assert json_response(conn, 200) ==
               %{
                 "page" => 1,
                 "total_count" => 1,
                 "txs" => [
                   %{
                     "hash" => to_string(transfer.transaction_hash),
                     "block_number" => transfer.block_number,
                     "timestamp" => utc_to_unix(block.timestamp),
                     "from" => to_string(user.eth_address),
                     "to" => to_string(to_user.eth_address),
                     "udt_id" => udt.id,
                     "udt_name" => udt.name,
                     "udt_symbol" => udt.symbol,
                     "transfer_value" => balance_to_view(transfer.amount, udt.decimal),
                     "udt_decimal" => udt.decimal,
                     "status" => to_string(block.status),
                     "polyjuice_status" => to_string(polyjuice.status),
                     "gas_limit" => to_string(polyjuice.gas_limit),
                     "gas_price" => to_string(polyjuice.gas_price),
                     "gas_used" => to_string(polyjuice.gas_used),
                     "transfer_count" => to_string(transfer.amount),
                     "nonce" => tx.nonce,
                     "log_index" => transfer.log_index
                   }
                 ]
               }
    end

    test "query by eth address", %{
      conn: conn,
      user: user,
      to_user: to_user,
      transfer: transfer,
      udt: udt,
      tx: tx,
      polyjuice: polyjuice,
      block: block
    } do
      conn =
        get(
          conn,
          ~p"/api/transfers?eth_address=#{to_string(user.eth_address)}"
        )

      assert json_response(conn, 200) ==
               %{
                 "page" => 1,
                 "total_count" => 1,
                 "txs" => [
                   %{
                     "hash" => to_string(transfer.transaction_hash),
                     "block_number" => transfer.block_number,
                     "timestamp" => utc_to_unix(block.timestamp),
                     "from" => to_string(user.eth_address),
                     "to" => to_string(to_user.eth_address),
                     "udt_id" => udt.id,
                     "udt_name" => udt.name,
                     "udt_symbol" => udt.symbol,
                     "transfer_value" => balance_to_view(transfer.amount, udt.decimal),
                     "udt_decimal" => udt.decimal,
                     "status" => to_string(block.status),
                     "polyjuice_status" => to_string(polyjuice.status),
                     "gas_limit" => to_string(polyjuice.gas_limit),
                     "gas_price" => to_string(polyjuice.gas_price),
                     "gas_used" => to_string(polyjuice.gas_used),
                     "transfer_count" => to_string(transfer.amount),
                     "nonce" => tx.nonce,
                     "log_index" => transfer.log_index
                   }
                 ]
               }
    end

    test "export by eth address", %{
      conn: conn,
      user: user,
      to_user: to_user,
      transfer: transfer,
      udt: udt,
      block: block
    } do
      conn =
        get(
          conn,
          ~p"/api/transfers?eth_address=#{to_string(user.eth_address)}&export=true"
        )

      assert response(conn, 200) ==
               "TxHash,BlockNumber,UnixTimestamp,FromAddress,ToAddress,Value\r\n" <>
                 "#{to_string(transfer.transaction_hash)}," <>
                 "#{transfer.block_number}," <>
                 "#{utc_to_unix(block.timestamp)}," <>
                 "#{to_string(user.eth_address)}," <>
                 "#{to_string(to_user.eth_address)}," <>
                 "#{balance_to_view(transfer.amount, udt.decimal)}\r\n"
    end

    test "query by udt address", %{
      conn: conn,
      user: user,
      to_user: to_user,
      transfer: transfer,
      udt: udt,
      tx: tx,
      polyjuice: polyjuice,
      block: block
    } do
      conn =
        get(
          conn,
          ~p"/api/transfers?udt_address=#{to_string(udt.contract_address_hash)}"
        )

      assert json_response(conn, 200) ==
               %{
                 "page" => 1,
                 "total_count" => 1,
                 "txs" => [
                   %{
                     "hash" => to_string(transfer.transaction_hash),
                     "block_number" => transfer.block_number,
                     "timestamp" => utc_to_unix(block.timestamp),
                     "from" => to_string(user.eth_address),
                     "to" => to_string(to_user.eth_address),
                     "udt_id" => udt.id,
                     "udt_name" => udt.name,
                     "udt_symbol" => udt.symbol,
                     "transfer_value" => balance_to_view(transfer.amount, udt.decimal),
                     "udt_decimal" => udt.decimal,
                     "status" => to_string(block.status),
                     "polyjuice_status" => to_string(polyjuice.status),
                     "gas_limit" => to_string(polyjuice.gas_limit),
                     "gas_price" => to_string(polyjuice.gas_price),
                     "gas_used" => to_string(polyjuice.gas_used),
                     "transfer_count" => to_string(transfer.amount),
                     "nonce" => tx.nonce,
                     "log_index" => transfer.log_index
                   }
                 ]
               }
    end

    test "export by udt address", %{
      conn: conn,
      user: user,
      to_user: to_user,
      transfer: transfer,
      udt: udt,
      block: block
    } do
      conn =
        get(
          conn,
          ~p"/api/transfers?udt_address=#{to_string(udt.contract_address_hash)}&export=true"
        )

      assert response(conn, 200) ==
               "TxHash,BlockNumber,UnixTimestamp,FromAddress,ToAddress,Value\r\n" <>
                 "#{to_string(transfer.transaction_hash)}," <>
                 "#{transfer.block_number}," <>
                 "#{utc_to_unix(block.timestamp)}," <>
                 "#{to_string(user.eth_address)}," <>
                 "#{to_string(to_user.eth_address)}," <>
                 "#{balance_to_view(transfer.amount, udt.decimal)}\r\n"
    end

    test "when tx have no erc20 records", %{conn: conn} do
      conn =
        get(
          conn,
          ~p"/api/transfers?tx_hash=0x5710b3d039850d5dd44e35949a8e23e519b6f8abc50c9c1932e8cf6f05b40f39&export=true"
        )

      assert conn.resp_body |> String.split("\r\n") |> Enum.drop(1) == [""]
    end

    test "when tx have erc20 records", %{conn: conn, tx: tx, transfer: transfer, udt: udt} do
      conn =
        get(
          conn,
          ~p"/api/transfers?tx_hash=#{to_string(tx.eth_hash)}&export=true"
        )

      assert conn.resp_body |> String.split("\r\n") |> Enum.drop(1) == [
               "#{transfer.from_address_hash |> to_string},#{transfer.to_address_hash |> to_string()},#{transfer.amount |> balance_to_view(udt.decimal)}",
               ""
             ]
    end
  end
end
