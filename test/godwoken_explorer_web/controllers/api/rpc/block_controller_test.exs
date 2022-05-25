defmodule GodwokenExplorerWeb.API.RPC.BlockControllerTest do
  use GodwokenExplorerWeb.ConnCase

  import GodwokenExplorer.Factory

  alias GodwokenExplorer.Chain

  describe "getblocknobytime" do
    test "with missing timestamp param", %{conn: conn} do
      response =
        conn
        |> get("/api/v1", %{
          "module" => "block",
          "action" => "getblocknobytime",
          "closest" => "after"
        })
        |> json_response(200)

      assert response["message"] =~ "Query parameter 'timestamp' is required"
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
    end

    test "with missing closest param", %{conn: conn} do
      response =
        conn
        |> get("/api/v1", %{
          "module" => "block",
          "action" => "getblocknobytime",
          "timestamp" => "1617019505"
        })
        |> json_response(200)

      assert response["message"] =~ "Query parameter 'closest' is required"
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
    end

    test "with an invalid timestamp param", %{conn: conn} do
      response =
        conn
        |> get("/api/v1", %{
          "module" => "block",
          "action" => "getblocknobytime",
          "timestamp" => "invalid",
          "closest" => " before"
        })
        |> json_response(200)

      assert response["message"] =~ "Invalid `timestamp` param"
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
    end

    test "with an invalid closest param", %{conn: conn} do
      response =
        conn
        |> get("/api/v1", %{
          "module" => "block",
          "action" => "getblocknobytime",
          "timestamp" => "1617019505",
          "closest" => "invalid"
        })
        |> json_response(200)

      assert response["message"] =~ "Invalid `closest` param"
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
    end

    test "with valid params and before", %{conn: conn} do
      timestamp_string = "1617020209"
      {:ok, timestamp} = Chain.param_to_block_timestamp(timestamp_string)
      block = insert(:block, timestamp: timestamp)

      {timestamp_int, _} = Integer.parse(timestamp_string)

      timestamp_in_the_future_str =
        (timestamp_int + 1)
        |> to_string()

      expected_result = %{
        "blockNumber" => "#{block.number}"
      }

      assert response =
               conn
               |> get("/api/v1", %{
                 "module" => "block",
                 "action" => "getblocknobytime",
                 "timestamp" => "#{timestamp_in_the_future_str}",
                 "closest" => "before"
               })
               |> json_response(200)

      assert response["result"] == expected_result
      assert response["status"] == "1"
      assert response["message"] == "OK"
    end

    test "with valid params and after", %{conn: conn} do
      timestamp_string = "1617020209"
      {:ok, timestamp} = Chain.param_to_block_timestamp(timestamp_string)
      block = insert(:block, timestamp: timestamp)

      {timestamp_int, _} = Integer.parse(timestamp_string)

      timestamp_in_the_past_str =
        (timestamp_int - 1)
        |> to_string()

      expected_result = %{
        "blockNumber" => "#{block.number}"
      }

      assert response =
               conn
               |> get("/api/v1", %{
                 "module" => "block",
                 "action" => "getblocknobytime",
                 "timestamp" => "#{timestamp_in_the_past_str}",
                 "closest" => "after"
               })
               |> json_response(200)

      assert response["result"] == expected_result
      assert response["status"] == "1"
      assert response["message"] == "OK"
    end
  end
end
