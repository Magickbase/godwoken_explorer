defmodule GodwokenExplorerWeb.API.RPC.StatsControllerTest do
  use GodwokenExplorerWeb.ConnCase

  import GodwokenExplorer.Factory

  describe "tokensupply" do
    test "with missing contract address", %{conn: conn} do
      params = %{
        "module" => "stats",
        "action" => "tokensupply"
      }

      assert response =
               conn
               |> get("/api/v1", params)
               |> json_response(200)

      assert response["message"] =~ "contract address is required"
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
      assert :ok = ExJsonSchema.Validator.validate(tokensupply_schema(), response)
    end

    test "with an invalid contract address hash", %{conn: conn} do
      params = %{
        "module" => "stats",
        "action" => "tokensupply",
        "contractaddress" => "badhash"
      }

      assert response =
               conn
               |> get("/api/v1", params)
               |> json_response(200)

      assert response["message"] =~ "Invalid contract address format"
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
      assert :ok = ExJsonSchema.Validator.validate(tokensupply_schema(), response)
    end

    test "with a contract address that doesn't exist", %{conn: conn} do
      params = %{
        "module" => "stats",
        "action" => "tokensupply",
        "contractaddress" => "0x8bf38d4764929064f2d4d3a56520a76ab3df415b"
      }

      assert response =
               conn
               |> get("/api/v1", params)
               |> json_response(200)

      assert response["message"] =~ "contract address not found"
      assert response["status"] == "0"
      assert Map.has_key?(response, "result")
      refute response["result"]
      assert :ok = ExJsonSchema.Validator.validate(tokensupply_schema(), response)
    end

    test "with valid contract address", %{conn: conn} do
      account = insert(:ckb_contract_account)
      udt = insert(:ckb_udt, account: account)

      params = %{
        "module" => "stats",
        "action" => "tokensupply",
        "contractaddress" => to_string(account.eth_address)
      }

      assert response =
               conn
               |> get("/api/v1", params)
               |> json_response(200)

      assert response["result"] == to_string(udt.supply)
      assert response["status"] == "1"
      assert response["message"] == "OK"
      assert :ok = ExJsonSchema.Validator.validate(tokensupply_schema(), response)
    end
  end

  defp tokensupply_schema do
    resolve_schema(%{
      "type" => ["string", "null"]
    })
  end

  defp resolve_schema(result \\ %{}) do
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
