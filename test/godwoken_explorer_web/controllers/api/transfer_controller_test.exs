defmodule GodwokenExplorerWeb.API.TransferControllerTest do
  use GodwokenExplorerWeb.ConnCase

  import GodwokenExplorer.Factory

  import GodwokenRPC.Util,
    only: [
      balance_to_view: 2
    ]

  describe "json" do
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

  describe "export" do
    setup do
      tx = insert(:transaction) |> with_polyjuice()
      %{tx: tx}
    end

    test "when tx have no erc20 records", %{conn: conn, tx: tx} do
      conn =
        get(
          conn,
          Routes.transfer_path(conn, :index,
            tx_hash: tx.eth_hash |> to_string(),
            export: true
          )
        )

      assert conn.resp_body |> String.split("\r\n") |> Enum.drop(1) == [""]
    end

    test "when tx have erc20 records", %{conn: conn, tx: tx} do
      udt = insert(:native_udt)

      tt =
        insert(:token_transfer,
          transaction: tx,
          token_contract_address_hash: udt.contract_address_hash
        )

      conn =
        get(
          conn,
          Routes.transfer_path(conn, :index,
            tx_hash: tx.eth_hash |> to_string(),
            export: true
          )
        )

      assert conn.resp_body |> String.split("\r\n") |> Enum.drop(1) == [
               "#{tt.from_address_hash |> to_string},#{tt.to_address_hash |> to_string()},#{tt.amount |> balance_to_view(udt.decimal)}",
               ""
             ]
    end
  end
end
