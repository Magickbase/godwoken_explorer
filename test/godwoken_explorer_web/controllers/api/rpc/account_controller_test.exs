defmodule GodwokenExplorerWeb.API.RPC.AccountControllerTest do
  use GodwokenExplorerWeb.ConnCase

  import GodwokenExplorer.Factory

  alias GodwokenExplorer.{Account, Repo, Transaction, Polyjuice}
  alias Decimal, as: D

  describe "balance" do
    setup do
      %Account{script_hash: bridge_script_hash} = insert(:ckb_account)

      %Account{id: id, eth_address: native_eth_address} = insert(:ckb_contract_account)

      insert(:ckb_udt, bridge_account_id: id)

      %Account{eth_address: user_eth_address} = insert(:user)
      %Account{eth_address: user2_eth_address} = insert(:user)

      insert(
        :current_bridged_udt_balance,
        address_hash: user_eth_address,
        udt_id: 1,
        udt_script_hash: bridge_script_hash,
        value: D.new(555_500_000_000)
      )

      insert(
        :current_udt_balance,
        address_hash: user_eth_address,
        token_contract_address_hash: native_eth_address,
        value: D.new(666_600_000_000)
      )

      insert(
        :current_bridged_udt_balance,
        address_hash: user2_eth_address,
        udt_id: 1,
        udt_script_hash: bridge_script_hash,
        value: D.new(555_000_000_000)
      )

      insert(
        :current_udt_balance,
        address_hash: user2_eth_address,
        token_contract_address_hash: native_eth_address,
        value: D.new(666_000_000_000)
      )

      %{user_eth_address: user_eth_address, user2_eth_address: user2_eth_address}
    end

    test "with missing address hash", %{conn: conn} do
      params = %{
        "module" => "account",
        "action" => "balance"
      }

      assert response =
               conn
               |> get("/api/v1", params)
               |> json_response(200)

      assert response["message"] =~ "'address' is required"
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
    end

    test "with an invalid address hash", %{conn: conn} do
      params = %{
        "module" => "account",
        "action" => "balance",
        "address" => "badhash"
      }

      assert response =
               conn
               |> get("/api/v1", params)
               |> json_response(200)

      assert response["message"] =~ "Invalid address hash"
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
    end

    test "return balance of single address", %{conn: conn, user_eth_address: user_eth_address} do
      params = %{
        "module" => "account",
        "action" => "balance",
        "address" => "#{user_eth_address}"
      }

      assert response =
               conn
               |> get("/api/v1", params)
               |> json_response(200)

      assert response["result"] == "666600000000"
      assert response["status"] == "1"
      assert response["message"] == "OK"
    end

    test "return balance of multiple address", %{
      conn: conn,
      user_eth_address: user_eth_address,
      user2_eth_address: user2_eth_address
    } do
      params = %{
        "module" => "account",
        "action" => "balance",
        "address" => "#{user_eth_address},#{user2_eth_address}"
      }

      assert response =
               conn
               |> get("/api/v1", params)
               |> json_response(200)

      expected_result = [
        %{"balance" => "666000000000", "address" => "#{user2_eth_address}"},
        %{"balance" => "666600000000", "address" => "#{user_eth_address}"}
      ]

      assert response["result"] == expected_result
      assert response["status"] == "1"
      assert response["message"] == "OK"
    end
  end

  describe "txlist" do
    test "with missing address hash", %{conn: conn} do
      params = %{
        "module" => "account",
        "action" => "txlist"
      }

      assert response =
               conn
               |> get("/api/v1", params)
               |> json_response(200)

      assert response["message"] =~ "'address' is required"
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
    end

    test "with an invalid address hash", %{conn: conn} do
      params = %{
        "module" => "account",
        "action" => "txlist",
        "address" => "badhash"
      }

      assert response =
               conn
               |> get("/api/v1", params)
               |> json_response(200)

      assert response["message"] =~ "Invalid address format"
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
    end

    test "with an address that doesn't exist", %{conn: conn} do
      params = %{
        "module" => "account",
        "action" => "txlist",
        "address" => "0x8bf38d4764929064f2d4d3a56520a76ab3df415b"
      }

      assert response =
               conn
               |> get("/api/v1", params)
               |> json_response(200)

      assert response["result"] == []
      assert response["status"] == "0"
      assert response["message"] == "No transactions found"
    end

    test "with a valid address", %{conn: conn} do
      user = insert(:user)
      contract = insert(:polyjuice_contract_account)
      block = insert(:block)

      transaction =
        %Transaction{} =
        :transaction
        |> insert(
          from_account: user,
          to_account: contract,
          block_number: block.number,
          block: block
        )
        |> with_polyjuice()

      polyjuice = Repo.get_by(Polyjuice, tx_hash: transaction.hash)

      # ^ 'status: :ok' means `isError` in response should be '0'

      params = %{
        "module" => "account",
        "action" => "txlist",
        "address" => "#{user.eth_address}"
      }

      expected_result = [
        %{
          "blockNumber" => "#{transaction.block_number}",
          "timeStamp" => "#{DateTime.to_unix(block.timestamp)}",
          "hash" => "#{transaction.eth_hash}",
          "nonce" => "#{transaction.nonce}",
          "blockHash" => "#{block.hash}",
          "transactionIndex" => "#{polyjuice.transaction_index}",
          "from" => "#{user.eth_address}",
          "to" => "#{contract.eth_address}",
          "value" => "#{polyjuice.value}",
          "gas" => "#{polyjuice.gas_limit}",
          "gasPrice" => "#{polyjuice.gas_price}",
          "txreceipt_status" => "1",
          "input" => "#{polyjuice.input}",
          "contractAddress" => "#{polyjuice.created_contract_address_hash}",
          "gasUsed" => "#{polyjuice.gas_used}"
        }
      ]

      assert response =
               conn
               |> get("/api/v1", params)
               |> json_response(200)

      assert response["result"] == expected_result
      assert response["status"] == "1"
      assert response["message"] == "OK"
    end
  end

  describe "tokenlist" do
    test "with missing address hash", %{conn: conn} do
      params = %{
        "module" => "account",
        "action" => "tokentx"
      }

      assert response =
               conn
               |> get("/api/v1", params)
               |> json_response(200)

      assert response["message"] =~ "address is required"
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
    end

    test "with an invalid address hash", %{conn: conn} do
      params = %{
        "module" => "account",
        "action" => "tokentx",
        "address" => "badhash"
      }

      assert response =
               conn
               |> get("/api/v1", params)
               |> json_response(200)

      assert response["message"] =~ "Invalid address format"
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
    end

    test "with an address that doesn't exist", %{conn: conn} do
      params = %{
        "module" => "account",
        "action" => "tokentx",
        "address" => "0x8bf38d4764929064f2d4d3a56520a76ab3df415b"
      }

      assert response =
               conn
               |> get("/api/v1", params)
               |> json_response(200)

      assert response["result"] == []
      assert response["status"] == "0"
      assert response["message"] == "No token transfers found"
    end

    test "returns all the required fields", %{conn: conn} do
      user = insert(:user)
      user2 = insert(:user)
      contract = insert(:polyjuice_contract_account)

      udt =
        insert(:native_udt,
          id: contract.id,
          type: :native,
          name: "CKB",
          symbol: "CKB",
          decimal: 8,
          contract_address_hash: contract.eth_address
        )

      block = insert(:block)

      transaction =
        %Transaction{} =
        :transaction
        |> insert(
          from_account: user,
          to_account: contract,
          block_number: block.number,
          block: block
        )
        |> with_polyjuice()

      polyjuice = Repo.get_by(Polyjuice, tx_hash: transaction.hash)

      token_transfer =
        insert(:token_transfer,
          block: transaction.block,
          transaction: transaction,
          block_number: block.number,
          from_address_hash: user.eth_address,
          to_address_hash: user2.eth_address,
          token_contract_address_hash: contract.eth_address,
          transaction_hash: transaction.eth_hash
        )

      params = %{
        "module" => "account",
        "action" => "tokentx",
        "address" => "#{user.eth_address}"
      }

      expected_result = [
        %{
          "blockNumber" => to_string(transaction.block_number),
          "timeStamp" => to_string(DateTime.to_unix(block.timestamp)),
          "hash" => to_string(token_transfer.transaction_hash),
          "nonce" => to_string(transaction.nonce),
          "blockHash" => to_string(block.hash),
          "from" => to_string(user.eth_address),
          "contractAddress" => to_string(token_transfer.token_contract_address_hash),
          "to" => to_string(user2.eth_address),
          "value" => to_string(token_transfer.amount),
          "tokenName" => udt.name,
          "tokenSymbol" => udt.symbol,
          "tokenDecimal" => to_string(udt.decimal),
          "transactionIndex" => to_string(polyjuice.transaction_index),
          "gas" => to_string(polyjuice.gas_limit),
          "gasPrice" => to_string(polyjuice.gas_price),
          "gasUsed" => to_string(polyjuice.gas_used),
          "logIndex" => to_string(token_transfer.log_index),
          "input" => to_string(polyjuice.input)
        }
      ]

      assert response =
               conn
               |> get("/api/v1", params)
               |> json_response(200)

      assert response["result"] == expected_result
      assert response["status"] == "1"
      assert response["message"] == "OK"

      contract_params = %{
        "module" => "account",
        "action" => "tokentx",
        "address" => "#{user.eth_address}",
        "contractaddress" => "#{contract.eth_address}"
      }

      assert response =
               conn
               |> get("/api/v1", contract_params)
               |> json_response(200)

      assert response["result"] == expected_result
      assert response["status"] == "1"
      assert response["message"] == "OK"
    end

    test "with an invalid contract address", %{conn: conn} do
      params = %{
        "module" => "account",
        "action" => "tokentx",
        "address" => "0x8bf38d4764929064f2d4d3a56520a76ab3df415b",
        "contractaddress" => "invalid"
      }

      assert response =
               conn
               |> get("/api/v1", params)
               |> json_response(200)

      assert response["message"] =~ "Invalid contract address format"
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
    end
  end

  describe "tokenbalance" do
    test "without required params", %{conn: conn} do
      params = %{
        "module" => "account",
        "action" => "tokenbalance"
      }

      assert response =
               conn
               |> get("/api/v1", params)
               |> json_response(200)

      assert response["message"] =~ "missing: address, contractaddress"
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
      assert :ok = ExJsonSchema.Validator.validate(tokenbalance_schema(), response)
    end

    test "with contract address but without address", %{conn: conn} do
      params = %{
        "module" => "account",
        "action" => "tokenbalance",
        "contractaddress" => "0x8bf38d4764929064f2d4d3a56520a76ab3df415b"
      }

      assert response =
               conn
               |> get("/api/v1", params)
               |> json_response(200)

      assert response["message"] =~ "missing: address"
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
      assert :ok = ExJsonSchema.Validator.validate(tokenbalance_schema(), response)
    end

    test "with address but without contract address", %{conn: conn} do
      params = %{
        "module" => "account",
        "action" => "tokenbalance",
        "address" => "0x8bf38d4764929064f2d4d3a56520a76ab3df415b"
      }

      assert response =
               conn
               |> get("/api/v1", params)
               |> json_response(200)

      assert response["message"] =~ "missing: contractaddress"
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
      assert :ok = ExJsonSchema.Validator.validate(tokenbalance_schema(), response)
    end

    test "with an invalid contract address hash", %{conn: conn} do
      params = %{
        "module" => "account",
        "action" => "tokenbalance",
        "contractaddress" => "badhash",
        "address" => "badhash"
      }

      assert response =
               conn
               |> get("/api/v1", params)
               |> json_response(200)

      assert response["message"] =~ "Invalid contractaddress format"
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
      assert :ok = ExJsonSchema.Validator.validate(tokenbalance_schema(), response)
    end

    test "with an invalid address hash", %{conn: conn} do
      params = %{
        "module" => "account",
        "action" => "tokenbalance",
        "contractaddress" => "0x8bf38d4764929064f2d4d3a56520a76ab3df415b",
        "address" => "badhash"
      }

      assert response =
               conn
               |> get("/api/v1", params)
               |> json_response(200)

      assert response["message"] =~ "Invalid address format"
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
      assert :ok = ExJsonSchema.Validator.validate(tokenbalance_schema(), response)
    end

    test "with a contract address and address that doesn't exist", %{conn: conn} do
      params = %{
        "module" => "account",
        "action" => "tokenbalance",
        "contractaddress" => "0x8bf38d4764929064f2d4d3a56520a76ab3df415b",
        "address" => "0x9bf38d4764929064f2d4d3a56520a76ab3df415b"
      }

      assert response =
               conn
               |> get("/api/v1", params)
               |> json_response(200)

      assert response["result"] == "0"
      assert response["status"] == "1"
      assert response["message"] == "OK"
      assert :ok = ExJsonSchema.Validator.validate(tokenbalance_schema(), response)
    end

    test "with contract address and address without row in token_balances table", %{conn: conn} do
      %Account{eth_address: native_eth_address} = insert(:ckb_contract_account)

      insert(:ckb_udt)

      %Account{eth_address: user_eth_address} = insert(:user)

      params = %{
        "module" => "account",
        "action" => "tokenbalance",
        "contractaddress" => to_string(native_eth_address),
        "address" => to_string(user_eth_address)
      }

      assert response =
               conn
               |> get("/api/v1", params)
               |> json_response(200)

      assert response["result"] == "0"
      assert response["status"] == "1"
      assert response["message"] == "OK"
      assert :ok = ExJsonSchema.Validator.validate(tokenbalance_schema(), response)
    end

    test "with contract address and address with existing balance in token_balances table", %{
      conn: conn
    } do
      %Account{eth_address: native_eth_address} = insert(:ckb_contract_account)

      insert(:ckb_udt)

      %Account{eth_address: user_eth_address} = insert(:user)

      account_udt =
        insert(
          :current_udt_balance,
          address_hash: user_eth_address,
          udt_id: 1,
          token_contract_address_hash: native_eth_address,
          value: D.new(555_500_000_000)
        )

      params = %{
        "module" => "account",
        "action" => "tokenbalance",
        "contractaddress" => to_string(native_eth_address),
        "address" => to_string(user_eth_address)
      }

      assert response =
               conn
               |> get("/api/v1", params)
               |> json_response(200)

      assert response["result"] == to_string(account_udt.value)
      assert response["status"] == "1"
      assert response["message"] == "OK"
      assert :ok = ExJsonSchema.Validator.validate(tokenbalance_schema(), response)
    end
  end

  defp tokenbalance_schema, do: resolve_schema(%{"type" => ["string", "null"]})

  defp resolve_schema(result) do
    %{
      "type" => "object",
      "properties" => %{
        "message" => %{"type" => "string"},
        "status" => %{"type" => "string"}
      }
    }
    |> put_in(["properties", "result"], result)
    |> ExJsonSchema.Schema.resolve()
  end
end
