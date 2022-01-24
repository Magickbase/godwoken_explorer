defmodule GodwokenExplorerWeb.API.AccountControllerTest do
  use GodwokenExplorer, :schema
  use GodwokenExplorerWeb.ConnCase

  describe "show" do
    test "when id is not integer", %{conn: conn} do
      conn =
        get(
          conn,
          Routes.account_path(conn, :show, "YokaiRouter")
        )

      assert json_response(conn, 404) ==
               %{"errors" => %{"detail" => "", "status" => "404", "title" => "not found"}}
    end
  end
end
