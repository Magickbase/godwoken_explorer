defmodule GodwokenExplorerWeb.API.RPC.ContractControllerTest do
  use GodwokenExplorerWeb.ConnCase

  import GodwokenExplorer.Factory

  setup do
    Code.ensure_loaded(GodwokenExplorerWeb.API.RPC.ContractController)

    account = insert(:polyjuice_contract_account)

    contract = insert(:smart_contract, account: account)
    %{account: account, contract: contract}
  end

  describe "getabi" do
    test "with missing address hash", %{conn: conn} do
      params = %{
        "module" => "contract",
        "action" => "getabi"
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
        "module" => "contract",
        "action" => "getabi",
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

    test "with an address that doesn't exist", %{conn: conn} do
      params = %{
        "module" => "contract",
        "action" => "getabi",
        "address" => "0x8bf38d4764929064f2d4d3a56520a76ab3df415b"
      }

      assert response =
               conn
               |> get("/api/v1", params)
               |> json_response(200)

      assert response["result"] == nil
      assert response["status"] == "0"
      assert response["message"] == "Contract not found"
    end

    test "with a verified contract address", %{conn: conn, account: account, contract: contract} do
      params = %{
        "module" => "contract",
        "action" => "getabi",
        "address" => to_string(account.eth_address)
      }

      assert response =
               conn
               |> get("/api/v1", params)
               |> json_response(200)

      assert response["result"] == Jason.encode!(contract.abi)
      assert response["status"] == "1"
      assert response["message"] == "OK"
    end
  end

  describe "getsourcecode" do
    test "with missing address hash", %{conn: conn} do
      params = %{
        "module" => "contract",
        "action" => "getsourcecode"
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
        "module" => "contract",
        "action" => "getsourcecode",
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

    test "with an address that doesn't exist", %{conn: conn} do
      params = %{
        "module" => "contract",
        "action" => "getsourcecode",
        "address" => "0x8bf38d4764929064f2d4d3a56520a76ab3df415b"
      }

      assert response =
               conn
               |> get("/api/v1", params)
               |> json_response(200)

      assert response["result"] == nil
      assert response["message"] == "Contract not found"
    end

    test "with a verified contract address", %{conn: conn, account: account, contract: contract} do
      params = %{
        "module" => "contract",
        "action" => "getsourcecode",
        "address" => to_string(account.eth_address)
      }

      expected_result = [
        %{
          "SourceCode" => contract.contract_source_code,
          "ABI" => Jason.encode!(contract.abi)
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
end
