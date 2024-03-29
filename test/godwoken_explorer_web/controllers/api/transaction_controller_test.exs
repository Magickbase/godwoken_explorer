defmodule GodwokenExplorerWeb.API.TransactionControllerTest do
  use GodwokenExplorerWeb.ConnCase

  import GodwokenExplorer.Factory

  import GodwokenRPC.Util,
    only: [
      balance_to_view: 2
    ]

  alias Decimal, as: D

  setup do
    insert(:ckb_udt)
    insert(:ckb_account)

    block = insert(:block)
    eth_user = insert(:user)

    polyjuice_creator_tx =
      insert(:polyjuice_creator_tx,
        from_account: eth_user,
        block: block,
        block_number: block.number,
        index: 0
      )

    polyjuice_creator = insert(:polyjuice_creator, transaction: polyjuice_creator_tx)
    polyjuice_contract_account = insert(:polyjuice_contract_account)

    insert(:native_udt,
      id: polyjuice_contract_account.id,
      contract_address_hash: polyjuice_contract_account.eth_address
    )

    smart_contract = insert(:smart_contract, account: polyjuice_contract_account)
    insert(:contract_method)

    tx =
      insert(:transaction,
        block: block,
        block_number: block.number,
        from_account: eth_user,
        to_account: polyjuice_contract_account,
        index: 1
      )

    polyjuice = insert(:polyjuice, transaction: tx)

    %{
      tx: tx,
      eth_user: eth_user,
      polyjuice_contract_account: polyjuice_contract_account,
      block: block,
      polyjuice: polyjuice,
      smart_contract: smart_contract,
      polyjuice_creator_tx: polyjuice_creator_tx,
      polyjuice_creator: polyjuice_creator
    }
  end

  setup_all do
    on_exit(fn ->
      Supervisor.terminate_child(GodwokenExplorer.Supervisor, {ConCache, :transaction_count})
      Supervisor.restart_child(GodwokenExplorer.Supervisor, {ConCache, :transaction_count})
    end)
  end

  describe "index" do
    test "list user all txs", %{
      conn: conn,
      tx: tx,
      eth_user: eth_user,
      polyjuice_contract_account: polyjuice_contract_account,
      block: block,
      polyjuice: polyjuice,
      smart_contract: smart_contract,
      polyjuice_creator_tx: polyjuice_creator_tx
    } do
      polyjuice_creator_account = insert(:polyjuice_creator_account)
      receiver_user = insert(:user)

      native_transfer_tx =
        insert(:transaction,
          block: block,
          block_number: block.number,
          from_account: eth_user,
          to_account: polyjuice_creator_account,
          index: 2,
          args:
            "0xffffff504f4c590068bf00000000000000a007c2da51000000000000000000000000e867ce97461d310000000000000000000000715ab282b873b79a7be8b0e8c13c4e8966a52040"
        )

      native_transfer_polyjuice =
        insert(:polyjuice,
          transaction: native_transfer_tx,
          native_transfer_address_hash: receiver_user.eth_address
        )

      conn =
        get(
          conn,
          ~p"/api/txs?eth_address=#{to_string(eth_user.eth_address)}"
        )

      assert json_response(conn, 200) ==
               %{
                 "page" => 1,
                 "total_count" => 3,
                 "txs" => [
                   %{
                     "block_number" => block.number,
                     "l1_block_number" => nil,
                     "block_hash" => to_string(block.hash),
                     "fee" =>
                       D.mult(
                         native_transfer_polyjuice.gas_price,
                         native_transfer_polyjuice.gas_used
                       )
                       |> balance_to_view(18),
                     "from" => to_string(eth_user.eth_address),
                     "to" => to_string(polyjuice_creator_account.script_hash),
                     "to_alias" => "Deploy Contract",
                     "gas_limit" => native_transfer_polyjuice.gas_limit |> balance_to_view(0),
                     "gas_price" => native_transfer_polyjuice.gas_price |> balance_to_view(18),
                     "gas_used" => native_transfer_polyjuice.gas_used |> balance_to_view(0),
                     "hash" => to_string(native_transfer_tx.eth_hash),
                     "nonce" => native_transfer_tx.nonce,
                     "timestamp" =>
                       block.timestamp |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix(),
                     "type" => "polyjuice",
                     "value" => native_transfer_polyjuice.value |> balance_to_view(8),
                     "status" => "finalized",
                     "created_contract_address_hash" => "",
                     "native_transfer_address_hash" =>
                       native_transfer_polyjuice.native_transfer_address_hash |> to_string(),
                     "index" => native_transfer_polyjuice.transaction_index,
                     "method" => nil,
                     "transaction_index" => native_transfer_polyjuice.transaction_index,
                     "polyjuice_status" => "succeed"
                   },
                   %{
                     "block_number" => block.number,
                     "l1_block_number" => nil,
                     "block_hash" => to_string(block.hash),
                     "fee" =>
                       D.mult(polyjuice.gas_price, polyjuice.gas_used) |> balance_to_view(18),
                     "from" => to_string(eth_user.eth_address),
                     "to" => to_string(polyjuice_contract_account.eth_address),
                     "to_alias" => smart_contract.name,
                     "gas_limit" => polyjuice.gas_limit |> balance_to_view(0),
                     "gas_price" => polyjuice.gas_price |> balance_to_view(18),
                     "gas_used" => polyjuice.gas_used |> balance_to_view(0),
                     "hash" => to_string(tx.eth_hash),
                     "nonce" => tx.nonce,
                     "timestamp" =>
                       block.timestamp |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix(),
                     "type" => "polyjuice",
                     "value" => polyjuice.value |> balance_to_view(8),
                     "status" => "finalized",
                     "polyjuice_status" => "succeed",
                     "created_contract_address_hash" => "",
                     "native_transfer_address_hash" => nil,
                     "index" => polyjuice.transaction_index,
                     "method" => nil,
                     "transaction_index" => polyjuice.transaction_index
                   },
                   %{
                     "block_number" => block.number,
                     "l1_block_number" => nil,
                     "block_hash" => to_string(block.hash),
                     "fee" => "",
                     "from" => to_string(eth_user.eth_address),
                     "to" => "0x946d08cc356c4fe13bc49929f1f709611fe0a2aaa336efb579dad4ca197d1551",
                     "to_alias" =>
                       "0x946d08cc356c4fe13bc49929f1f709611fe0a2aaa336efb579dad4ca197d1551",
                     "gas_limit" => nil,
                     "gas_price" => "",
                     "gas_used" => nil,
                     "hash" => to_string(polyjuice_creator_tx.hash),
                     "nonce" => polyjuice_creator_tx.nonce,
                     "timestamp" =>
                       block.timestamp |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix(),
                     "type" => "polyjuice_creator",
                     "value" => "",
                     "status" => "finalized",
                     "polyjuice_status" => nil,
                     "created_contract_address_hash" => "",
                     "native_transfer_address_hash" => nil,
                     "index" => nil,
                     "method" => nil,
                     "transaction_index" => nil
                   }
                 ]
               }
    end

    test "lists user txs of contract", %{
      conn: conn,
      tx: tx,
      eth_user: eth_user,
      polyjuice_contract_account: polyjuice_contract_account,
      block: block,
      polyjuice: polyjuice,
      smart_contract: smart_contract
    } do
      conn =
        get(
          conn,
          ~p"/api/txs?eth_address=#{to_string(eth_user.eth_address)}&contract_address=#{to_string(polyjuice_contract_account.eth_address)}"
        )

      assert json_response(conn, 200) ==
               %{
                 "page" => 1,
                 "total_count" => 1,
                 "txs" => [
                   %{
                     "block_number" => block.number,
                     "l1_block_number" => nil,
                     "block_hash" => to_string(block.hash),
                     "fee" =>
                       D.mult(polyjuice.gas_price, polyjuice.gas_used) |> balance_to_view(18),
                     "from" => to_string(eth_user.eth_address),
                     "to" => to_string(polyjuice_contract_account.eth_address),
                     "to_alias" => smart_contract.name,
                     "gas_limit" => polyjuice.gas_limit |> balance_to_view(0),
                     "gas_price" => polyjuice.gas_price |> balance_to_view(18),
                     "gas_used" => polyjuice.gas_used |> balance_to_view(0),
                     "hash" => to_string(tx.eth_hash),
                     "nonce" => tx.nonce,
                     "timestamp" =>
                       block.timestamp |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix(),
                     "type" => "polyjuice",
                     "value" => polyjuice.value |> balance_to_view(8),
                     "status" => "finalized",
                     "polyjuice_status" => "succeed",
                     "created_contract_address_hash" => "",
                     "native_transfer_address_hash" => nil,
                     "index" => polyjuice.transaction_index,
                     "method" => nil,
                     "transaction_index" => polyjuice.transaction_index
                   }
                 ]
               }
    end

    test "lists txs of block", %{
      conn: conn,
      tx: tx,
      eth_user: eth_user,
      polyjuice_contract_account: polyjuice_contract_account,
      block: block,
      polyjuice: polyjuice,
      smart_contract: smart_contract,
      polyjuice_creator_tx: polyjuice_creator_tx
    } do
      conn =
        get(
          conn,
          ~p"/api/txs?block_hash=#{to_string(block.hash)}"
        )

      assert json_response(conn, 200) ==
               %{
                 "page" => 1,
                 "total_count" => 2,
                 "txs" => [
                   %{
                     "block_number" => block.number,
                     "l1_block_number" => nil,
                     "block_hash" => to_string(block.hash),
                     "fee" =>
                       D.mult(polyjuice.gas_price, polyjuice.gas_used) |> balance_to_view(18),
                     "from" => to_string(eth_user.eth_address),
                     "to" => to_string(polyjuice_contract_account.eth_address),
                     "to_alias" => smart_contract.name,
                     "gas_limit" => polyjuice.gas_limit |> balance_to_view(0),
                     "gas_price" => polyjuice.gas_price |> balance_to_view(18),
                     "gas_used" => polyjuice.gas_used |> balance_to_view(0),
                     "hash" => to_string(tx.eth_hash),
                     "nonce" => tx.nonce,
                     "timestamp" =>
                       block.timestamp |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix(),
                     "type" => "polyjuice",
                     "value" => polyjuice.value |> balance_to_view(8),
                     "status" => "finalized",
                     "polyjuice_status" => "succeed",
                     "created_contract_address_hash" => "",
                     "native_transfer_address_hash" => nil,
                     "index" => polyjuice.transaction_index,
                     "method" => nil,
                     "transaction_index" => polyjuice.transaction_index
                   },
                   %{
                     "block_number" => block.number,
                     "l1_block_number" => nil,
                     "block_hash" => to_string(block.hash),
                     "fee" => "",
                     "from" => to_string(eth_user.eth_address),
                     "to" => to_string(polyjuice_creator_tx.to_account.script_hash),
                     "to_alias" => to_string(polyjuice_creator_tx.to_account.script_hash),
                     "gas_limit" => nil,
                     "gas_price" => "",
                     "gas_used" => nil,
                     "hash" => to_string(polyjuice_creator_tx.hash),
                     "nonce" => polyjuice_creator_tx.nonce,
                     "timestamp" =>
                       block.timestamp |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix(),
                     "type" => "polyjuice_creator",
                     "value" => "",
                     "status" => "finalized",
                     "polyjuice_status" => nil,
                     "created_contract_address_hash" => "",
                     "native_transfer_address_hash" => nil,
                     "index" => nil,
                     "method" => nil,
                     "transaction_index" => nil
                   }
                 ]
               }
    end

    test "lists all txs", %{
      conn: conn,
      tx: tx,
      eth_user: eth_user,
      polyjuice_contract_account: polyjuice_contract_account,
      block: block,
      polyjuice: polyjuice,
      smart_contract: smart_contract,
      polyjuice_creator_tx: polyjuice_creator_tx
    } do
      conn =
        get(
          conn,
          ~p"/api/txs"
        )

      assert json_response(conn, 200) ==
               %{
                 "page" => 1,
                 "total_count" => 2,
                 "txs" => [
                   %{
                     "block_number" => block.number,
                     "l1_block_number" => nil,
                     "block_hash" => to_string(block.hash),
                     "fee" =>
                       D.mult(polyjuice.gas_price, polyjuice.gas_used) |> balance_to_view(18),
                     "from" => to_string(eth_user.eth_address),
                     "to" => to_string(polyjuice_contract_account.eth_address),
                     "to_alias" => smart_contract.name,
                     "gas_limit" => polyjuice.gas_limit |> balance_to_view(0),
                     "gas_price" => polyjuice.gas_price |> balance_to_view(18),
                     "gas_used" => polyjuice.gas_used |> balance_to_view(0),
                     "hash" => to_string(tx.eth_hash),
                     "nonce" => tx.nonce,
                     "timestamp" =>
                       block.timestamp |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix(),
                     "type" => "polyjuice",
                     "value" => polyjuice.value |> balance_to_view(8),
                     "status" => "finalized",
                     "polyjuice_status" => "succeed",
                     "created_contract_address_hash" => "",
                     "native_transfer_address_hash" => nil,
                     "index" => polyjuice.transaction_index,
                     "method" => nil,
                     "transaction_index" => polyjuice.transaction_index
                   },
                   %{
                     "block_number" => block.number,
                     "l1_block_number" => nil,
                     "block_hash" => to_string(block.hash),
                     "fee" => "",
                     "from" => to_string(eth_user.eth_address),
                     "to" => to_string(polyjuice_creator_tx.to_account.script_hash),
                     "to_alias" => to_string(polyjuice_creator_tx.to_account.script_hash),
                     "gas_limit" => nil,
                     "gas_price" => "",
                     "gas_used" => nil,
                     "hash" => to_string(polyjuice_creator_tx.hash),
                     "nonce" => polyjuice_creator_tx.nonce,
                     "timestamp" =>
                       block.timestamp |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix(),
                     "type" => "polyjuice_creator",
                     "value" => "",
                     "status" => "finalized",
                     "polyjuice_status" => nil,
                     "created_contract_address_hash" => "",
                     "native_transfer_address_hash" => nil,
                     "index" => nil,
                     "method" => nil,
                     "transaction_index" => nil
                   }
                 ]
               }
    end

    test "export tx by hash", %{
      conn: conn,
      tx: tx,
      eth_user: eth_user,
      polyjuice_contract_account: polyjuice_contract_account,
      block: block,
      polyjuice: polyjuice,
      polyjuice_creator_tx: polyjuice_creator_tx
    } do
      conn =
        get(
          conn,
          ~p"/api/txs?eth_address=#{to_string(eth_user.eth_address)}&export=true"
        )

      transaction = %{
        "block_number" => block.number,
        "block_hash" => to_string(block.hash),
        "from" => to_string(eth_user.eth_address),
        "to" => to_string(polyjuice_contract_account.eth_address),
        "hash" => to_string(tx.eth_hash),
        "timestamp" => block.timestamp |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix(),
        "type" => "polyjuice",
        "value" => polyjuice.value |> balance_to_view(8),
        "status" => "finalized",
        "polyjuice_status" => "succeed"
      }

      polyjuice_creator_transaction = %{
        "block_number" => block.number,
        "block_hash" => to_string(block.hash),
        "from" => to_string(eth_user.eth_address),
        "to" => "0x946d08cc356c4fe13bc49929f1f709611fe0a2aaa336efb579dad4ca197d1551",
        "hash" => to_string(polyjuice_creator_tx.hash),
        "timestamp" => block.timestamp |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix(),
        "type" => "polyjuice_creator",
        "value" => "",
        "status" => "finalized",
        "polyjuice_status" => nil
      }

      assert response(conn, 200) ==
               "TxHash,BlockNumber,UnixTimestamp,FromAddress,ToAddress,Value,Type,PolyjuiceStatus,BlockStatus\r\n" <>
                 "#{transaction["hash"]}," <>
                 "#{transaction["block_number"]}," <>
                 "#{transaction["timestamp"]}," <>
                 "#{transaction["from"]}," <>
                 "#{transaction["to"]}," <>
                 "#{transaction["value"]}," <>
                 "#{transaction["type"]}," <>
                 "#{transaction["polyjuice_status"]}," <>
                 "#{transaction["status"]}\r\n" <>
                 "#{polyjuice_creator_transaction["hash"]}," <>
                 "#{polyjuice_creator_transaction["block_number"]}," <>
                 "#{polyjuice_creator_transaction["timestamp"]}," <>
                 "#{polyjuice_creator_transaction["from"]}," <>
                 "#{polyjuice_creator_transaction["to"]}," <>
                 "#{polyjuice_creator_transaction["value"]}," <>
                 "#{polyjuice_creator_transaction["type"]}," <>
                 "#{polyjuice_creator_transaction["polyjuice_status"]}," <>
                 "#{polyjuice_creator_transaction["status"]}\r\n"
    end

    test "export tx by block hash", %{
      conn: conn,
      tx: tx,
      eth_user: eth_user,
      polyjuice_contract_account: polyjuice_contract_account,
      block: block,
      polyjuice: polyjuice,
      polyjuice_creator_tx: polyjuice_creator_tx
    } do
      conn =
        get(
          conn,
          ~p"/api/txs?block_hash=#{to_string(block.hash)}&export=true"
        )

      transaction = %{
        "block_number" => block.number,
        "block_hash" => to_string(block.hash),
        "from" => to_string(eth_user.eth_address),
        "to" => to_string(polyjuice_contract_account.eth_address),
        "hash" => to_string(tx.eth_hash),
        "timestamp" => block.timestamp |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix(),
        "type" => "polyjuice",
        "value" => polyjuice.value |> balance_to_view(8),
        "status" => "finalized",
        "polyjuice_status" => "succeed"
      }

      polyjuice_creator_transaction = %{
        "block_number" => block.number,
        "block_hash" => to_string(block.hash),
        "from" => to_string(eth_user.eth_address),
        "to" => "0x946d08cc356c4fe13bc49929f1f709611fe0a2aaa336efb579dad4ca197d1551",
        "hash" => to_string(polyjuice_creator_tx.hash),
        "timestamp" => block.timestamp |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix(),
        "type" => "polyjuice_creator",
        "value" => "",
        "status" => "finalized",
        "polyjuice_status" => nil
      }

      assert response(conn, 200) ==
               "TxHash,BlockNumber,UnixTimestamp,FromAddress,ToAddress,Value,Type,PolyjuiceStatus,BlockStatus\r\n" <>
                 "#{transaction["hash"]}," <>
                 "#{transaction["block_number"]}," <>
                 "#{transaction["timestamp"]}," <>
                 "#{transaction["from"]}," <>
                 "#{transaction["to"]}," <>
                 "#{transaction["value"]}," <>
                 "#{transaction["type"]}," <>
                 "#{transaction["polyjuice_status"]}," <>
                 "#{transaction["status"]}\r\n" <>
                 "#{polyjuice_creator_transaction["hash"]}," <>
                 "#{polyjuice_creator_transaction["block_number"]}," <>
                 "#{polyjuice_creator_transaction["timestamp"]}," <>
                 "#{polyjuice_creator_transaction["from"]}," <>
                 "#{polyjuice_creator_transaction["to"]}," <>
                 "#{polyjuice_creator_transaction["value"]}," <>
                 "#{polyjuice_creator_transaction["type"]}," <>
                 "#{polyjuice_creator_transaction["polyjuice_status"]}," <>
                 "#{polyjuice_creator_transaction["status"]}\r\n"
    end
  end

  describe "GET #show" do
    test "when query by gw hash return eth_hash", %{
      conn: conn,
      tx: tx
    } do
      conn =
        get(
          conn,
          ~p"/api/txs/#{to_string(tx.hash)}"
        )

      assert json_response(conn, 400) == %{
               "errors" => %{
                 "detail" => "The eth hash is #{to_string(tx.eth_hash)}.",
                 "status" => "400",
                 "title" => "Please use eth hash query, not godwoken hash"
               }
             }
    end

    test "when query with not invalid hash", %{conn: conn} do
      conn =
        get(
          conn,
          ~p"/api/txs/123"
        )

      assert json_response(conn, 200) == %{
               "message" => "Oops! An invalid Txn hash has been entered: 123"
             }
    end

    test "show polyjuice tx by hash", %{
      conn: conn,
      tx: tx,
      eth_user: eth_user,
      polyjuice_contract_account: polyjuice_contract_account,
      block: block,
      polyjuice: polyjuice,
      smart_contract: smart_contract
    } do
      conn =
        get(
          conn,
          ~p"/api/txs/#{to_string(tx.eth_hash)}"
        )

      assert json_response(conn, 200) ==
               %{
                 "block_number" => block.number,
                 "l1_block_number" => nil,
                 "block_hash" => to_string(block.hash),
                 "fee" => D.mult(polyjuice.gas_price, polyjuice.gas_used) |> balance_to_view(18),
                 "from" => to_string(eth_user.eth_address),
                 "to" => to_string(polyjuice_contract_account.eth_address),
                 "to_alias" => smart_contract.name,
                 "gas_limit" => polyjuice.gas_limit |> balance_to_view(0),
                 "gas_price" => polyjuice.gas_price |> balance_to_view(18),
                 "gas_used" => polyjuice.gas_used |> balance_to_view(0),
                 "hash" => to_string(tx.eth_hash),
                 "nonce" => tx.nonce,
                 "timestamp" =>
                   block.timestamp |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix(),
                 "type" => "polyjuice",
                 "value" => polyjuice.value |> balance_to_view(8),
                 "status" => "finalized",
                 "polyjuice_status" => "succeed",
                 "created_contract_address_hash" => "",
                 "native_transfer_address_hash" => nil,
                 "index" => polyjuice.transaction_index,
                 "transaction_index" => polyjuice.transaction_index,
                 "contract_abi" => smart_contract.abi,
                 "input" => to_string(polyjuice.input)
               }
    end

    test "show polyjuice creator tx by hash", %{
      conn: conn,
      block: block,
      eth_user: eth_user,
      polyjuice_creator_tx: polyjuice_creator_tx,
      polyjuice_creator: polyjuice_creator
    } do
      conn =
        get(
          conn,
          ~p"/api/txs/#{to_string(polyjuice_creator_tx.hash)}"
        )

      assert json_response(conn, 200) ==
               %{
                 "block_number" => block.number,
                 "l1_block_number" => nil,
                 "block_hash" => to_string(block.hash),
                 "fee" => "",
                 "from" => to_string(eth_user.eth_address),
                 "to" => to_string(polyjuice_creator_tx.to_account.script_hash),
                 "to_alias" => to_string(polyjuice_creator_tx.to_account.script_hash),
                 "gas_limit" => nil,
                 "gas_price" => "",
                 "gas_used" => nil,
                 "hash" => to_string(polyjuice_creator_tx.hash),
                 "nonce" => polyjuice_creator_tx.nonce,
                 "timestamp" =>
                   block.timestamp |> DateTime.from_naive!("Etc/UTC") |> DateTime.to_unix(),
                 "type" => "polyjuice_creator",
                 "value" => "",
                 "status" => "finalized",
                 "polyjuice_status" => nil,
                 "created_contract_address_hash" => "",
                 "native_transfer_address_hash" => nil,
                 "index" => nil,
                 "transaction_index" => nil,
                 "fee_amount" => polyjuice_creator.fee_amount,
                 "input" => nil,
                 "created_account" => "0x48a466ed98a517bab6158209bd54c6b29281b733"
               }
    end
  end
end
