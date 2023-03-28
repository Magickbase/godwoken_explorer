defmodule GodwokenExplorer.Graphql.SmartContractTest do
  use GodwokenExplorerWeb.ConnCase
  import GodwokenExplorer.Factory, only: [insert!: 2, insert: 1, insert: 2]
  import Mock

  alias GodwokenExplorer.Graphql.Sourcify

  setup do
    ckb_account = insert(:ckb_account)
    ckb_contract_account = insert(:ckb_contract_account)
    _ = insert(:ckb_udt)
    _ = insert(:ckb_native_udt)

    for index <- 1..3 do
      polyjuice_contract_account = insert!(:polyjuice_contract_account, transaction_count: index)
      _smart_contract = insert(:smart_contract, account: polyjuice_contract_account)
    end

    polyjuice_contract_account = insert!(:polyjuice_contract_account, transaction_count: 4)
    smart_contract = insert!(:smart_contract, account: polyjuice_contract_account)

    _cub =
      insert(:current_udt_balance,
        address_hash: smart_contract.account.eth_address,
        token_contract_address_hash: ckb_contract_account.eth_address,
        value: 10000,
        token_type: :erc20
      )

    GodwokenExplorer.Graphql.Workers.UpdateSmartContractCKB.trigger_update_all_smart_contracts_ckbs()

    [
      smart_contract: smart_contract,
      polyjuice_contract_account: polyjuice_contract_account,
      ckb_account: ckb_account,
      ckb_contract_account: ckb_contract_account
    ]
  end

  test "graphql: smart_contract ", %{
    conn: conn,
    smart_contract: smart_contract
    # ckb_account: ckb_account
  } do
    account = smart_contract.account

    query = """
    query {
      smart_contract(
        input: { contract_address: "#{account.eth_address}" }
      ) {
        name
        account_id
        account {
          eth_address
        }
        ckb_balance
      }
    }
    """

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    assert match?(
             %{
               "data" => %{
                 "smart_contract" => %{"ckb_balance" => "10000"}
               }
             },
             json_response(conn, 200)
           )
  end

  test "graphql: smart_contract with sourcify_metadata ", %{
    conn: conn,
    smart_contract: smart_contract
    # ckb_account: ckb_account
  } do
    with_mock GodwokenExplorer.Graphql.SourcifyExport,
      get_metadata: fn _address ->
        {:ok,
         [
           %{
             "content" =>
               "{\"compiler\":{\"version\":\"0.8.9+commit.e5eed63a\"},\"language\":\"Solidity\",\"output\":{\"abi\":[{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"_unlockTime\",\"type\":\"uint256\"},{\"internalType\":\"address\",\"name\":\"_owner\",\"type\":\"address\"}],\"stateMutability\":\"payable\",\"type\":\"constructor\"},{\"anonymous\":false,\"inputs\":[{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"amount\",\"type\":\"uint256\"},{\"indexed\":false,\"internalType\":\"uint256\",\"name\":\"when\",\"type\":\"uint256\"}],\"name\":\"Withdrawal\",\"type\":\"event\"},{\"inputs\":[{\"internalType\":\"uint256\",\"name\":\"_unlockTime\",\"type\":\"uint256\"}],\"name\":\"deposit\",\"outputs\":[],\"stateMutability\":\"payable\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"owner\",\"outputs\":[{\"internalType\":\"address payable\",\"name\":\"\",\"type\":\"address\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"unlockTime\",\"outputs\":[{\"internalType\":\"uint256\",\"name\":\"\",\"type\":\"uint256\"}],\"stateMutability\":\"view\",\"type\":\"function\"},{\"inputs\":[],\"name\":\"withdraw\",\"outputs\":[],\"stateMutability\":\"nonpayable\",\"type\":\"function\"}],\"devdoc\":{\"kind\":\"dev\",\"methods\":{},\"version\":1},\"userdoc\":{\"kind\":\"user\",\"methods\":{},\"version\":1}},\"settings\":{\"compilationTarget\":{\"contracts/Transfer.sol\":\"LockTest\"},\"evmVersion\":\"london\",\"libraries\":{},\"metadata\":{\"bytecodeHash\":\"ipfs\"},\"optimizer\":{\"enabled\":false,\"runs\":200},\"remappings\":[]},\"sources\":{\"contracts/Transfer.sol\":{\"keccak256\":\"0x308b3b8785abc49ec1bb6cdcd7944cf8ed3f9d8c778d048bcc2ebbdf85bbb428\",\"urls\":[\"bzz-raw://8d36d6ff8160402d22189e30cd7ec4764f29196ac653d5f3ab7dfb0e57d40396\",\"dweb:/ipfs/QmSfPjvBie1fcVYMVkXRVJQ2ne3NCvveuJEuD3P25CQb9E\"]},\"hardhat/console.sol\":{\"keccak256\":\"0x72b6a1d297cd3b033d7c2e4a7e7864934bb767db6453623f1c3082c6534547f4\",\"license\":\"MIT\",\"urls\":[\"bzz-raw://a8cb8681076e765c214e0d51cac989325f6b98e315eaae06ee0cbd5a9f084763\",\"dweb:/ipfs/QmNWGHi4zmjxQTYN3NMGnJd49jBT5dE4bxTdWEaDuJrC6N\"]}},\"version\":1}",
             "name" => "metadata.json",
             "path" =>
               "/home/data/repository/contracts/full_match/71401/0x2998dcc6C7A8F7ecC6AA72cf75a88dE6824F3aE6/metadata.json"
           },
           %{
             "content" =>
               "// SPDX-License-Identifier UNLICENSED\npragma solidity ^0.8.9;\n\nimport \"hardhat/console.sol\";\n\n// Author: @keith-cy\ncontract LockTest {\n    uint public unlockTime;\n    address payable public owner;\n\n    event Withdrawal(uint amount, uint when);\n\n    constructor(uint _unlockTime,address _owner) payable {\n     // require(block.timestamp < _unlockTime, \"Unlock time should be in the future\");\n      unlockTime = _unlockTime;\n      owner = payable(_owner);\n     // owner = payable(msg.sender);\n    }\n\n    function withdraw() public {\n      console.log(\"Unlock time is %o and block timestamp is %o\", unlockTime, block.timestamp);\n     // require(block.timestamp >= unlockTime, \"You can't withdraw yet\");\n      emit Withdrawal(address(this).balance, block.timestamp);\n      owner.transfer(address(this).balance);\n    }\n\n    function deposit(uint _unlockTime) public payable {\n     // require(block.timestamp < _unlockTime, \"Unlock time should be in the future\");\n      unlockTime = _unlockTime;\n     // owner = payable(msg.sender);\n    }\n}\n\n",
             "name" => "Transfer.sol",
             "path" =>
               "/home/data/repository/contracts/full_match/71401/0x2998dcc6C7A8F7ecC6AA72cf75a88dE6824F3aE6/sources/contracts/Transfer.sol"
           },
           %{
             "content" =>
               "// SPDX-License-Identifier: MIT\npragma solidity >= 0.4.22 <0.9.0;\n\nlibrary console {\n\taddress constant CONSOLE_ADDRESS = address(0x000000000000000000636F6e736F6c652e6c6f67);\n\n\tfunction _sendLogPayload(bytes memory payload) private view {\n\t\tuint256 payloadLength = payload.length;\n\t\taddress consoleAddress = CONSOLE_ADDRESS;\n\t\tassembly {\n\t\t\tlet payloadStart := add(payload, 32)\n\t\t\tlet r := staticcall(gas(), consoleAddress, payloadStart, payloadLength, 0, 0)\n\t\t}\n\t}\n\n\tfunction log() internal view {\n\t\t_sendLogPayload(abi.encodeWithSignature(\"log()\"));\n\t}\n\n\tfunction logInt(int p0) internal view {\n\t\t_sendLogPayload(abi.encodeWithSignature(\"log(int)\", p0));\n\t}\n\n\tfunction logUint(uint p0) internal view {\n\t\t_sendLogPayload(abi.encodeWithSignature(\"log(uint)\", p0));\n\t}\n\n\tfunction logString(string memory p0) internal view {\n\t\t_sendLogPayload(abi.encodeWithSignature(\"log(string)\", p0));\n\t}\n\n\tfunction logBool(bool p0) internal view {\n\t\t_sendLogPayload(abi.encodeWithSignature(\"log(bool)\", p0));\n\t}\n\n\tfunction logAddress(address p0) internal view {\n\t\t_sendLogPayload(abi.encodeWithSignature(\"log(address)\", p0));\n\t}\n\n\tfunction logBytes(bytes memory p0) internal view {\n\t\t_sendLogPayload(abi.encodeWithSignature(\"log(bytes)\", p0));\n\t}\n\n\tfunction logBytes1(bytes1 p0) internal view {\n\t\t_sendLogPayload(abi.encodeWithSignature(\"log(bytes1)\", p0));\n\t}\n\n\tfunction logBytes2(bytes2 p0) internal view {\n\t\t_sendLogPayload(abi.encodeWithSignature(\"log(bytes2)\", p0));\n\t}\n\n\tfunction logBytes3(bytes3 p0) internal view {\n\t\t_sendLogPayload(abi.encodeWithSignature(\"log(bytes3)\", p0));\n\t}\n\n\tfunction logBytes4(bytes4 p0) internal view {\n\t\t_sendLogPayload(abi.encodeWithSignature(\"log(bytes4)\", p0));\n\t}\n\n\tfunction logBytes5(bytes5 p0) internal view {\n\t\t_sendLogPayload(abi.encodeWithSignature(\"log(bytes5)\", p0));\n\t}\n\n\tfunction logBytes6(bytes6 p0) internal view {\n\t\t_sendLogPayload(abi.encodeWithSignature(\"log(bytes6)\", p0));\n\t}\n\n\tfunction logBytes7(bytes7 p0) internal view {\n\t\t_sendLogPayload(abi.encodeWithSignature(\"log(bytes7)\", p0));\n\t}\n\n\tfunction logBytes8(bytes8 p0) internal view {\n\t\t_sendLogPayload(abi.encodeWithSignature(\"log(bytes8)\", p0));\n\t}\n\n\tfunction logBytes9(bytes9 p0) internal view {\n\t\t_sendLogPayload(abi.encodeWithSignature(\"log(bytes9)\", p0));\n\t}\n\n\tfunction logBytes10(bytes10 p0) internal view {\n\t\t_sendLogPayload(abi.encodeWithSignature(\"log(bytes10)\", p0));\n\t}\n\n\tfunction logBytes11(bytes11 p0) internal view {\n\t\t_sendLogPayload(abi.encodeWithSignature(\"log(bytes11)\", p0));\n\t}\n\n\tfunction logBytes12(bytes12 p0) internal view {\n\t\t_sendLogPayload(abi.encodeWithSignature(\"log(bytes12)\", p0));\n\t}\n\n\tfunction logBytes13(bytes13 p0) internal view {\n\t\t_sendLogPayload(abi.encodeWithSignature(\"log(bytes13)\", p0));\n\t}\n\n\tfunction logBytes14(bytes14 p0) internal view {\n\t\t_sendLogPayload(abi.encodeWithSignature(\"log(bytes14)\", p0));\n\t}\n\n\tfunction logBytes15(bytes15 p0) internal view {\n\t\t_sendLogPayload(abi.encodeWithSignature(\"log(bytes15)\", p0));\n\t}\n\n\tfunction logBytes16(bytes16 p0) internal view {\n\t\t_sendLogPayload(abi.encodeWithSignature(\"log(bytes16)\", p0));\n\t}\n\n\tfunction logBytes17(bytes17 p0) internal view {\n\t\t_sendLogPayload(abi.encodeWithSignature(\"log(bytes17)\", p0));\n\t}\n\n\tfunction logBytes18(bytes18 p0) internal view {\n\t\t_sendLogPayload(abi.encodeWithSignature(\"log(bytes18)\", p0));\n\t}\n\n\tfunction logBytes19(bytes19 p0) internal view {\n\t\t_sendLogPayload(abi.encodeWithSignature(\"log(bytes19)\", p0));\n\t}\n\n\tfunction logBytes20(bytes20 p0) internal view {\n\t\t_sendLogPayload(abi.encodeWithSignature(\"log(bytes20)\", p0));\n\t}\n\n\tfunction logBytes21(bytes21 p0) internal view {\n\t\t_sendLogPayload(abi.encodeWithSignature(\"log(bytes21)\", p0));\n\t}\n\n\tfunction logBytes22(bytes22 p0) internal view {\n\t\t_sendLogPayload(abi.encodeWithSignature(\"log(bytes22)\", p0));\n\t}\n\n\tfunction logBytes23(bytes23 p0) internal view {\n\t\t_sendLogPayload(abi.encodeWithSignature(\"log(bytes23)\", p0));\n\t}\n\n\tfunction logBytes24(bytes24 p0) internal view {\n\t\t_sendLogPayload(abi.encodeWithSignature(\"log(bytes24)\", p0));\n\t}\n\n\tfunction logBytes25(bytes25 p0) internal view {\n\t\t_sendLogPayload(abi.encodeWithSi",
             "name" => "console.sol",
             "path" =>
               "/home/data/repository/contracts/full_match/71401/0x2998dcc6C7A8F7ecC6AA72cf75a88dE6824F3aE6/sources/hardhat/console.sol"
           }
         ]}
      end do
      account = smart_contract.account
      Sourcify.verify_and_update_from_sourcify(account.eth_address |> to_string)

      query = """
      query {
        smart_contract(
          input: { contract_address: "#{account.eth_address}" }
        ) {
          name
          account_id
          account {
            eth_address
          }
          ckb_balance
          sourcify_metadata
        }
      }
      """

      conn =
        post(conn, "/graphql", %{
          "query" => query,
          "variables" => %{}
        })

      assert match?(
               %{
                 "data" => %{
                   "smart_contract" => %{"sourcify_metadata" => _}
                 }
               },
               json_response(conn, 200)
             )
    end
  end

  test "graphql: smart_contracts with condition",
       %{conn: conn, polyjuice_contract_account: a} do
    address = a.eth_address |> to_string()
    addresses = [address]

    query = """
    query {
      smart_contracts(
        input: {
          contract_addresses: "#{addresses}"
          limit: 2
          sorter: [
            { sort_type: DESC, sort_value: CKB_BALANCE }
          ]
        }
      ) {
        entries {
          name
          account_id
          account {
            eth_address
          }
          ckb_balance
        }
        metadata {
          total_count
          after
          before
        }
      }
    }
    """

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "smart_contracts" => %{
          "entries" => [%{"ckb_balance" => "10000"} | _],
          "metadata" => %{
            "total_count" => 1,
            "after" => _after_value
          }
        }
      }
    } = json_response(conn, 200)
  end

  test "graphql: smart_contracts with EX_TX_COUNT sorter ", %{
    conn: conn
  } do
    query = """
    query {
      smart_contracts(
        input: {
          limit: 2
          sorter: [
            { sort_type: DESC, sort_value: EX_TX_COUNT }
          ]
        }
      ) {
        entries {
          name
          account_id
          account {
            eth_address
            transaction_count
          }
          ckb_balance
        }
        metadata {
          total_count
          after
          before
        }
      }
    }
    """

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "smart_contracts" => %{
          "entries" => [%{"ckb_balance" => "10000", "account" => %{"transaction_count" => 4}} | _],
          "metadata" => %{
            "total_count" => 4,
            "after" => _after_value
          }
        }
      }
    } = json_response(conn, 200)
  end

  test "graphql: smart_contracts with ckb_balance_sorter", %{conn: conn} do
    query = """
    query {
      smart_contracts(
        input: {
          limit: 2
          sorter: [
            { sort_type: DESC, sort_value: CKB_BALANCE },
            { sort_type: DESC, sort_value: EX_TX_COUNT }
          ]
        }
      ) {
        entries {
          name
          account_id
          account {
            eth_address
          }
          ckb_balance
        }
        metadata {
          total_count
          after
          before
        }
      }
    }
    """

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "smart_contracts" => %{
          "entries" => [%{"ckb_balance" => "10000"} | _],
          "metadata" => %{
            "total_count" => 4,
            "after" => _after_value
          }
        }
      }
    } = json_response(conn, 200)
  end

  test "graphql: smart_contracts ", %{conn: conn} do
    # paginator with null value of name
    for _ <- 1..3 do
      _smart_contract = insert(:smart_contract, name: nil)
    end

    query = """
    query {
      smart_contracts(
        input: {
          limit: 5
          sorter: [
            { sort_type: ASC, sort_value: CKB_BALANCE }
            { sort_type: ASC, sort_value: ID }
            { sort_type: ASC, sort_value: NAME }
          ]
        }
      ) {
        entries {
          id
          name
          account_id
          account {
            eth_address
          }
          ckb_balance
        }
        metadata {
          total_count
          after
          before
        }
      }
    }
    """

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "smart_contracts" => %{
          "entries" => _,
          "metadata" => %{
            "total_count" => 7,
            "after" => after_value
          }
        }
      }
    } = json_response(conn, 200)

    query = """
    query {
      smart_contracts(
        input: {
          limit: 5
          after: "#{after_value}"
          sorter: [
            { sort_type: ASC, sort_value: CKB_BALANCE }
            { sort_type: ASC, sort_value: ID }
            { sort_type: ASC, sort_value: NAME }
          ]
        }
      ) {
        entries {
          id
          name
          account_id
          account {
            eth_address
          }
          ckb_balance
        }
        metadata {
          total_count
          after
          before
        }
      }
    }
    """

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    assert match?(
             %{
               "data" => %{
                 "smart_contracts" => %{
                   "entries" => [%{"name" => ""}, %{"ckb_balance" => "10000"}],
                   "metadata" => %{
                     "total_count" => 7
                   }
                 }
               }
             },
             json_response(conn, 200)
           )
  end

  test "graphql: smart_contracts with first page check ", %{conn: conn} do
    query = """
    query {
      smart_contracts(
        input: { limit: 2, sorter: [{ sort_type: DESC, sort_value: ID }] }
      ) {
        entries {
          id
        }
        metadata {
          total_count
          after
          before
        }
      }
    }
    """

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "smart_contracts" => %{
          "metadata" => %{
            "after" => after_value
          }
        }
      }
    } = json_response(conn, 200)

    query = smart_contract_with_first_page_check_query(after_value: after_value)

    _smart_contract = insert(:smart_contract)

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "smart_contracts" => %{
          "metadata" => %{
            "before" => before_value
          }
        }
      }
    } = json_response(conn, 200)

    query = smart_contract_with_first_page_check_query(before_value: before_value)

    conn =
      post(conn, "/graphql", %{
        "query" => query,
        "variables" => %{}
      })

    %{
      "data" => %{
        "smart_contracts" => %{
          "entries" => entries
        }
      }
    } = json_response(conn, 200)

    assert length(entries) == 2
  end

  defp smart_contract_with_first_page_check_query(before_value: before_value) do
    """
    query {
      smart_contracts(input: {limit: 2, before: "#{before_value}" sorter: [{ sort_type: DESC, sort_value: ID }] }) {
        entries {
          id
        }
        metadata {
          total_count
          after
          before
        }
      }
    }
    """
  end

  defp smart_contract_with_first_page_check_query(after_value: after_value) do
    """
    query {
      smart_contracts(input: {limit: 2, after: "#{after_value}" sorter: [{ sort_type: DESC, sort_value: ID }] }) {
        entries {
          id
        }
        metadata {
          total_count
          after
          before
        }
      }
    }
    """
  end
end
