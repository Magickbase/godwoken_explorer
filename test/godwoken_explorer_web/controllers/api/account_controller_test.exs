defmodule GodwokenExplorerWeb.API.AccountControllerTest do
  use GodwokenExplorerWeb.ConnCase

  import GodwokenExplorer.Factory
  import GodwokenRPC.Util, only: [balance_to_view: 2]

  setup do
    insert(:ckb_udt)
    insert(:ckb_account)
    :ok
  end

  describe "show" do
    test "return eth_user account by address", %{conn: conn} do
      user = insert(:user)

      conn =
        get(
          conn,
          ~p"/api/accounts/#{to_string(user.eth_address)}"
        )

      assert json_response(conn, 200) ==
               %{
                 "ckb" => "",
                 "eth_addr" => to_string(user.eth_address),
                 "id" => user.id,
                 "transfer_count" => 0,
                 "tx_count" => 0,
                 "type" => "eth_user",
                 "user" => %{"nonce" => user.nonce |> Integer.to_string(), "udt_list" => []}
               }
    end

    test "when user not exist but has transfer data", %{conn: conn} do
      udt_account = insert(:polyjuice_contract_account)
      udt = insert(:native_udt, contract_address_hash: udt_account.eth_address)
      cub = insert(:current_udt_balance, token_contract_address_hash: udt_account.eth_address)

      conn =
        get(
          conn,
          ~p"/api/accounts/#{to_string(cub.address_hash)}"
        )

      assert json_response(conn, 200) ==
               %{
                 "id" => nil,
                 "type" => "unknown",
                 "ckb" => "0",
                 "tx_count" => 0,
                 "eth_addr" => to_string(cub.address_hash),
                 "user" => %{
                   "nonce" => 0,
                   "udt_list" => [
                     %{
                       "balance" => balance_to_view(cub.value, udt.decimal),
                       "icon" => nil,
                       "id" => udt.id,
                       "name" => udt.name,
                       "symbol" => udt.symbol,
                       "type" => to_string(udt.type),
                       "udt_decimal" => udt.decimal,
                       "updated_at" => DateTime.to_iso8601(cub.updated_at)
                     }
                   ]
                 }
               }
    end

    test "return eth_user account by script hash", %{conn: conn} do
      user = insert(:user)

      conn =
        get(
          conn,
          ~p"/api/accounts/#{to_string(user.script_hash)}"
        )

      assert json_response(conn, 200) ==
               %{
                 "ckb" => "",
                 "eth_addr" => to_string(user.eth_address),
                 "id" => user.id,
                 "transfer_count" => 0,
                 "tx_count" => 0,
                 "type" => "eth_user",
                 "user" => %{"nonce" => user.nonce |> Integer.to_string(), "udt_list" => []}
               }
    end

    test "query by script hash but account not exist", %{conn: conn} do
      insert(:user)
      user = build(:user)

      conn =
        get(
          conn,
          ~p"/api/accounts/#{to_string(user.script_hash)}"
        )

      assert json_response(conn, 404) == %{
               "errors" => %{
                 "status" => "404",
                 "title" => "not found",
                 "detail" => ""
               }
             }
    end
  end
end
