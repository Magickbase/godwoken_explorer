defmodule GodwokenExplorerWeb.API.AccountControllerTest do
  use GodwokenExplorerWeb.ConnCase

  import GodwokenExplorer.Factory

  setup do
    insert(:ckb_udt)
    insert(:ckb_account)
    :ok
  end

  describe "show" do
    test "return eth_user account", %{conn: conn} do
      user = insert(:user)

      conn =
        get(
          conn,
          Routes.account_path(conn, :show, to_string(user.eth_address))
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
  end
end
