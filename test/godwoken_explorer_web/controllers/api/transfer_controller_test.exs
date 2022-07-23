defmodule GodwokenExplorerWeb.API.TransferControllerTest do
  use GodwokenExplorerWeb.ConnCase

  describe "index" do
    test "when eth address account not exist", %{conn: conn} do
      conn =
        get(
          conn,
          Routes.transfer_path(conn, :index,
            eth_address: "0x085a61d7164735FC5378E590b5ED1448561e1a48"
          )
        )

      assert json_response(conn, 200) == %{"txs" => [], "page" => 1, "total_count" => 0}
    end

    test "when tx_hash not exist", %{conn: conn} do
      conn =
        get(
          conn,
          Routes.transfer_path(conn, :index,
            tx_hash: "0x5710b3d039850d5dd44e35949a8e23e519b6f8abc50c9c1932e8cf6f05b40f39"
          )
        )

      assert json_response(conn, 200) ==
               %{"page" => 1, "total_count" => 0, "txs" => []}
    end
  end
end
