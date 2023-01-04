defmodule GodwokenExplorerWeb.API.SearchControllerTest do
  use GodwokenExplorerWeb.ConnCase

  import GodwokenExplorer.Factory

  describe "index" do
    test "when keyword is bigger than integer", %{conn: conn} do
      conn =
        get(
          conn,
          Routes.search_path(conn, :index, keyword: 932_955_726_849_138_728)
        )

      assert json_response(conn, 404) ==
               %{"errors" => %{"detail" => "", "status" => "404", "title" => "not found"}}
    end

    test "search polyjuice contract", %{conn: conn} do
      account = insert(:polyjuice_contract_account)

      conn =
        get(
          conn,
          Routes.search_path(conn, :index, keyword: to_string(account.eth_address))
        )

      assert json_response(conn, 200) == %{
               "id" => to_string(account.eth_address),
               "type" => "account"
             }
    end

    test "search not exist address will automatically insert", %{conn: conn} do
      address = "0xbFbE23681D99A158f632e64A31288946770c7A9e"

      conn =
        get(
          conn,
          Routes.search_path(conn, :index, keyword: address)
        )

      assert json_response(conn, 200) == %{
               "id" => address |> String.downcase(),
               "type" => "address"
             }
    end
  end
end
