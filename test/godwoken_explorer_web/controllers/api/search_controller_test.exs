defmodule GodwokenExplorerWeb.API.SearchControllerTest do
  use GodwokenExplorerWeb.ConnCase

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
  end
end
