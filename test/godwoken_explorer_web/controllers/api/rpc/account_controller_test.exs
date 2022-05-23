defmodule GodwokenExplorerWeb.API.RPC.AccountControllerTest do
  use GodwokenExplorer, :schema
  use GodwokenExplorerWeb.ConnCase

  import GodwokenExplorer.Factory

  alias Decimal, as: D

  describe "balance" do
    setup do
      %Account{short_address: bridge_short_address} = insert(:ckb_account)

      %Account{short_address: native_short_address} = insert(:ckb_contract_account)

      insert(:ckb_udt)

      %Account{short_address: user_short_address, eth_address: user_eth_address} = insert(:user)
      %Account{short_address: user2_short_address, eth_address: user2_eth_address} = insert(:user)

      insert(
        :account_udt,
        address_hash: user_short_address,
        udt_id: 1,
        token_contract_address_hash: bridge_short_address,
        balance: D.new(555_500_000_000)
      )

      insert(
        :account_udt,
        address_hash: user_short_address,
        token_contract_address_hash: native_short_address,
        balance: D.new(666_600_000_000)
      )

      insert(
        :account_udt,
        address_hash: user2_short_address,
        udt_id: 1,
        token_contract_address_hash: bridge_short_address,
        balance: D.new(555_000_000_000)
      )

      insert(
        :account_udt,
        address_hash: user2_short_address,
        token_contract_address_hash: native_short_address,
        balance: D.new(666_000_000_000)
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
        %{"account" => "#{user_eth_address}", "balance" => "666600000000"},
        %{"account" => "#{user2_eth_address}", "balance" => "666000000000"}
      ]

      assert response["result"] == expected_result
      assert response["status"] == "1"
      assert response["message"] == "OK"
    end
  end
end
