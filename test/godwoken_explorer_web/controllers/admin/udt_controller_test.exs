defmodule GodwokenExplorerWeb.Admin.UDTControllerTest do
  use GodwokenExplorerWeb.ConnCase

  alias GodwokenExplorer.Admin

  @create_attrs %{decimal: 42, icon: "some icon", name: "some name", script_hash: "some script_hash", supply: "120.5", symbol: "some symbol", type_script: %{}}
  @update_attrs %{decimal: 43, icon: "some updated icon", name: "some updated name", script_hash: "some updated script_hash", supply: "456.7", symbol: "some updated symbol", type_script: %{}}
  @invalid_attrs %{decimal: nil, icon: nil, name: nil, script_hash: nil, supply: nil, symbol: nil, type_script: nil}

  def fixture(:udt) do
    {:ok, udt} = Admin.create_udt(@create_attrs)
    udt
  end

  describe "index" do
    test "lists all udts", %{conn: conn} do
      conn = get conn, Routes.admin_udt_path(conn, :index)
      assert html_response(conn, 200) =~ "Udts"
    end
  end

  describe "new udt" do
    test "renders form", %{conn: conn} do
      conn = get conn, Routes.admin_udt_path(conn, :new)
      assert html_response(conn, 200) =~ "New Udt"
    end
  end

  describe "create udt" do
    test "redirects to show when data is valid", %{conn: conn} do
      conn = post conn, Routes.admin_udt_path(conn, :create), udt: @create_attrs

      assert %{id: id} = redirected_params(conn)
      assert redirected_to(conn) == Routes.admin_udt_path(conn, :show, id)

      conn = get conn, Routes.admin_udt_path(conn, :show, id)
      assert html_response(conn, 200) =~ "Udt Details"
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post conn, Routes.admin_udt_path(conn, :create), udt: @invalid_attrs
      assert html_response(conn, 200) =~ "New Udt"
    end
  end

  describe "edit udt" do
    setup [:create_udt]

    test "renders form for editing chosen udt", %{conn: conn, udt: udt} do
      conn = get conn, Routes.admin_udt_path(conn, :edit, udt)
      assert html_response(conn, 200) =~ "Edit Udt"
    end
  end

  describe "update udt" do
    setup [:create_udt]

    test "redirects when data is valid", %{conn: conn, udt: udt} do
      conn = put conn, Routes.admin_udt_path(conn, :update, udt), udt: @update_attrs
      assert redirected_to(conn) == Routes.admin_udt_path(conn, :show, udt)

      conn = get conn, Routes.admin_udt_path(conn, :show, udt)
      assert html_response(conn, 200) =~ "some updated icon"
    end

    test "renders errors when data is invalid", %{conn: conn, udt: udt} do
      conn = put conn, Routes.admin_udt_path(conn, :update, udt), udt: @invalid_attrs
      assert html_response(conn, 200) =~ "Edit Udt"
    end
  end

  describe "delete udt" do
    setup [:create_udt]

    test "deletes chosen udt", %{conn: conn, udt: udt} do
      conn = delete conn, Routes.admin_udt_path(conn, :delete, udt)
      assert redirected_to(conn) == Routes.admin_udt_path(conn, :index)
      assert_error_sent 404, fn ->
        get conn, Routes.admin_udt_path(conn, :show, udt)
      end
    end
  end

  defp create_udt(_) do
    udt = fixture(:udt)
    {:ok, udt: udt}
  end
end
