defmodule GodwokenExplorerWeb.API.PolyVersionControllerTest do
  use GodwokenExplorerWeb.ConnCase

  import Mock

  setup do
    :ok
  end

  describe "index" do
    test "return poly version", %{conn: conn} do
      with_mock GodwokenRPC,
        fetch_poly_version: fn ->
          {:ok,
           %{
             "versions" => %{
               "web3Version" => "1.12.0-rc2",
               "web3IndexerVersion" => "1.12.0-rc2",
               "godwokenVersion" => "1.12.0-rc1 4d0e922"
             }
           }}
        end do
        conn =
          get(
            conn,
            ~p"/api/poly_versions"
          )

        assert json_response(conn, 200) == %{
                 "web3Version" => "1.12.0-rc2",
                 "web3IndexerVersion" => "1.12.0-rc2",
                 "godwokenVersion" => "1.12.0-rc1 4d0e922"
               }
      end
    end
  end
end
