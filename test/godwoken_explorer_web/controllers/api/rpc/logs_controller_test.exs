defmodule GodwokenExplorerWeb.API.RPC.LogsControllerTest do
  use GodwokenExplorerWeb.ConnCase

  import GodwokenExplorer.Factory

  alias GodwokenExplorer.{Log, Polyjuice, Repo, Transaction}
  alias Decimal

  describe "getLogs" do
    test "without fromBlock, toBlock, address, and topic{x}", %{conn: conn} do
      params = %{
        "module" => "logs",
        "action" => "getLogs"
      }

      expected_message =
        "Required query parameters missing: fromBlock, toBlock, address and/or topic{x}"

      assert response =
               conn
               |> get("/api/v1", params)
               |> json_response(200)

      assert response["message"] == expected_message
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
    end

    test "without fromBlock", %{conn: conn} do
      params = %{
        "module" => "logs",
        "action" => "getLogs",
        "toBlock" => "10",
        "address" => "0x8bf38d4764929064f2d4d3a56520a76ab3df415b"
      }

      expected_message = "Required query parameters missing: fromBlock"

      assert response =
               conn
               |> get("/api/v1", params)
               |> json_response(200)

      assert response["message"] == expected_message
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
      assert :ok = ExJsonSchema.Validator.validate(getlogs_schema(), response)
    end

    test "without toBlock", %{conn: conn} do
      params = %{
        "module" => "logs",
        "action" => "getLogs",
        "fromBlock" => "5",
        "address" => "0x8bf38d4764929064f2d4d3a56520a76ab3df415b"
      }

      expected_message = "Required query parameters missing: toBlock"

      assert response =
               conn
               |> get("/api/v1", params)
               |> json_response(200)

      assert response["message"] == expected_message
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
      assert :ok = ExJsonSchema.Validator.validate(getlogs_schema(), response)
    end

    test "without address and topic{x}", %{conn: conn} do
      params = %{
        "module" => "logs",
        "action" => "getLogs",
        "fromBlock" => "5",
        "toBlock" => "10"
      }

      expected_message = "Required query parameters missing: address and/or topic{x}"

      assert response =
               conn
               |> get("/api/v1", params)
               |> json_response(200)

      assert response["message"] == expected_message
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
      assert :ok = ExJsonSchema.Validator.validate(getlogs_schema(), response)
    end

    test "without topic{x}_{x}_opr", %{conn: conn} do
      conditions = %{
        ["topic0", "topic1"] => "topic0_1_opr",
        ["topic0", "topic2"] => "topic0_2_opr",
        ["topic0", "topic3"] => "topic0_3_opr",
        ["topic1", "topic2"] => "topic1_2_opr",
        ["topic1", "topic3"] => "topic1_3_opr",
        ["topic2", "topic3"] => "topic2_3_opr"
      }

      for {[key1, key2], expectation} <- conditions do
        params = %{
          "module" => "logs",
          "action" => "getLogs",
          "fromBlock" => "5",
          "toBlock" => "10",
          key1 => "some topic",
          key2 => "some other topic"
        }

        expected_message = "Required query parameters missing: #{expectation}"

        assert response =
                 conn
                 |> get("/api/v1", params)
                 |> json_response(200)

        assert response["message"] == expected_message
        assert response["status"] == "0"
        assert Map.has_key?(response, "result")
        refute response["result"]
        assert :ok = ExJsonSchema.Validator.validate(getlogs_schema(), response)
      end
    end

    test "without multiple topic{x}_{x}_opr", %{conn: conn} do
      params = %{
        "module" => "logs",
        "action" => "getLogs",
        "fromBlock" => "5",
        "toBlock" => "10",
        "topic0" => "some topic",
        "topic1" => "some other topic",
        "topic2" => "some extra topic",
        "topic3" => "some different topic"
      }

      expected_message =
        "Required query parameters missing: " <>
          "topic0_1_opr, topic0_2_opr, topic0_3_opr, topic1_2_opr, topic1_3_opr, topic2_3_opr"

      assert response =
               conn
               |> get("/api/v1", params)
               |> json_response(200)

      assert response["message"] == expected_message
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
      assert :ok = ExJsonSchema.Validator.validate(getlogs_schema(), response)
    end

    test "with invalid fromBlock", %{conn: conn} do
      params = %{
        "module" => "logs",
        "action" => "getLogs",
        "fromBlock" => "invalid",
        "toBlock" => "10",
        "address" => "0x8bf38d4764929064f2d4d3a56520a76ab3df415b"
      }

      assert response =
               conn
               |> get("/api/v1", params)
               |> json_response(200)

      assert response["message"] =~ "Invalid fromBlock format"
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
      assert :ok = ExJsonSchema.Validator.validate(getlogs_schema(), response)
    end

    test "with invalid toBlock", %{conn: conn} do
      params = %{
        "module" => "logs",
        "action" => "getLogs",
        "fromBlock" => "5",
        "toBlock" => "invalid",
        "address" => "0x8bf38d4764929064f2d4d3a56520a76ab3df415b"
      }

      assert response =
               conn
               |> get("/api/v1", params)
               |> json_response(200)

      assert response["message"] =~ "Invalid toBlock format"
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
      assert :ok = ExJsonSchema.Validator.validate(getlogs_schema(), response)
    end

    test "with an invalid address hash", %{conn: conn} do
      params = %{
        "module" => "logs",
        "action" => "getLogs",
        "fromBlock" => "5",
        "toBlock" => "10",
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

    test "with invalid topic{x}_{x}_opr", %{conn: conn} do
      conditions = %{
        ["topic0", "topic1"] => "topic0_1_opr",
        ["topic0", "topic2"] => "topic0_2_opr",
        ["topic0", "topic3"] => "topic0_3_opr",
        ["topic1", "topic2"] => "topic1_2_opr",
        ["topic1", "topic3"] => "topic1_3_opr",
        ["topic2", "topic3"] => "topic2_3_opr"
      }

      for {[key1, key2], expectation} <- conditions do
        params = %{
          "module" => "logs",
          "action" => "getLogs",
          "fromBlock" => "5",
          "toBlock" => "10",
          key1 => "some topic",
          key2 => "some other topic",
          expectation => "invalid"
        }

        assert response =
                 conn
                 |> get("/api/v1", params)
                 |> json_response(200)

        assert response["message"] =~ "Invalid #{expectation} format"
        assert response["status"] == "0"
        assert Map.has_key?(response, "result")
        refute response["result"]
        assert :ok = ExJsonSchema.Validator.validate(getlogs_schema(), response)
      end
    end

    test "with an address that doesn't exist", %{conn: conn} do
      params = %{
        "module" => "logs",
        "action" => "getLogs",
        "fromBlock" => "5",
        "toBlock" => "10",
        "address" => "0x8bf38d4764929064f2d4d3a56520a76ab3df415b"
      }

      assert response =
               conn
               |> get("/api/v1", params)
               |> json_response(200)

      assert response["result"] == []
      assert response["status"] == "0"
      assert response["message"] == "No logs found"
      assert :ok = ExJsonSchema.Validator.validate(getlogs_schema(), response)
    end

    test "with a valid contract address", %{conn: conn} do
      contract = insert(:polyjuice_contract_account)

      block = insert(:block)

      transaction =
        %Transaction{} =
        :transaction
        |> insert(
          to_account: contract,
          block_number: block.number,
          block: block
        )
        |> with_polyjuice()

      polyjuice = Repo.get_by(Polyjuice, tx_hash: transaction.hash)

      log =
        insert(:log,
          address_hash: contract.eth_address,
          transaction_hash: transaction.eth_hash |> to_string()
        )

      params = %{
        "module" => "logs",
        "action" => "getLogs",
        "fromBlock" => "#{block.number}",
        "toBlock" => "#{block.number}",
        "address" => "#{contract.eth_address}"
      }

      expected_result = [
        %{
          "address" => "#{contract.eth_address}",
          "topics" => get_topics(log),
          "data" => "#{log.data}",
          "blockNumber" => integer_to_hex(transaction.block_number),
          "timeStamp" => datetime_to_hex(block.timestamp),
          "gasPrice" => decimal_to_hex(polyjuice.gas_price),
          "gasUsed" => decimal_to_hex(polyjuice.gas_used),
          "logIndex" => integer_to_hex(log.index),
          "transactionHash" => "#{transaction.eth_hash}",
          "transactionIndex" => integer_to_hex(polyjuice.transaction_index)
        }
      ]

      assert response =
               conn
               |> get("/api/v1", params)
               |> json_response(200)

      assert response["result"] == expected_result
      assert response["status"] == "1"
      assert response["message"] == "OK"
      assert :ok = ExJsonSchema.Validator.validate(getlogs_schema(), response)
    end
  end

  defp get_topics(%Log{
         first_topic: first_topic,
         second_topic: second_topic,
         third_topic: third_topic,
         fourth_topic: fourth_topic
       }) do
    [first_topic, second_topic, third_topic, fourth_topic]
  end

  defp integer_to_hex(integer), do: "0x" <> String.downcase(Integer.to_string(integer, 16))

  defp decimal_to_hex(decimal) do
    decimal
    |> Decimal.to_integer()
    |> integer_to_hex()
  end

  defp datetime_to_hex(datetime) do
    datetime
    |> DateTime.to_unix()
    |> integer_to_hex()
  end

  defp getlogs_schema do
    ExJsonSchema.Schema.resolve(%{
      "type" => "object",
      "properties" => %{
        "message" => %{"type" => "string"},
        "status" => %{"type" => "string"},
        "result" => %{
          "type" => ["array", "null"],
          "items" => %{
            "type" => "object",
            "properties" => %{
              "address" => %{"type" => "string"},
              "topics" => %{"type" => "array", "items" => %{"type" => ["string", "null"]}},
              "data" => %{"type" => "string"},
              "blockNumber" => %{"type" => "string"},
              "timeStamp" => %{"type" => "string"},
              "gasPrice" => %{"type" => "string"},
              "gasUsed" => %{"type" => "string"},
              "logIndex" => %{"type" => "string"},
              "transactionHash" => %{"type" => "string"},
              "transactionIndex" => %{"type" => "string"}
            }
          }
        }
      }
    })
  end
end
