defmodule GodwokenExplorerWeb.Admin.UDTController do
  use GodwokenExplorerWeb, :controller

  alias GodwokenExplorer.UDT

  plug(:put_root_layout, {GodwokenExplorerWeb.LayoutView, "torch.html"})
  plug(:put_layout, false)

  def index(conn, params) do
    case UDT.paginate_udts(params) do
      {:ok, assigns} ->
        render(conn, "index.html", assigns)

      error ->
        conn
        |> put_flash(:error, "There was an error rendering Udts. #{inspect(error)}")
        |> redirect(to: Routes.admin_udt_path(conn, :index))
    end
  end

  def new(conn, _params) do
    changeset = UDT.change_udt(%UDT{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"udt" => udt_params}) do
    case UDT.create_udt(udt_params) do
      {:ok, udt} ->
        conn
        |> put_flash(:info, "Udt created successfully.")
        |> redirect(to: Routes.admin_udt_path(conn, :show, udt))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    udt = UDT.get_udt!(id)
    render(conn, "show.html", udt: udt)
  end

  def edit(conn, %{"id" => id}) do
    udt = UDT.get_udt!(id)
    changeset = UDT.change_udt(udt)
    render(conn, "edit.html", udt: udt, changeset: changeset)
  end

  def update(conn, %{"id" => id, "udt" => udt_params}) do
    udt = UDT.get_udt!(id)

    case UDT.update_udt(udt, udt_params) do
      {:ok, udt} ->
        conn
        |> put_flash(:info, "Udt updated successfully.")
        |> redirect(to: Routes.admin_udt_path(conn, :show, udt))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", udt: udt, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    udt = UDT.get_udt!(id)
    {:ok, _udt} = UDT.delete_udt(udt)

    conn
    |> put_flash(:info, "Udt deleted successfully.")
    |> redirect(to: Routes.admin_udt_path(conn, :index))
  end
end
