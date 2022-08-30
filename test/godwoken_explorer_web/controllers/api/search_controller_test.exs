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
  end
end
