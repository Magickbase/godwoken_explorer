defmodule GodwokenExplorerWeb.Admin.SmartContractController do
  use GodwokenExplorerWeb, :controller

  alias GodwokenExplorer.Admin
  alias GodwokenExplorer.Admin.SmartContract

  require IEx

  plug(:put_root_layout, {GodwokenExplorerWeb.LayoutView, "torch.html"})
  plug(:put_layout, false)


  def index(conn, params) do
    case Admin.paginate_smart_contracts(params) do
      {:ok, assigns} ->
        render(conn, "index.html", assigns)
      error ->
        conn
        |> put_flash(:error, "There was an error rendering Smart contracts. #{inspect(error)}")
        |> redirect(to: Routes.admin_smart_contract_path(conn, :index))
    end
  end

  def new(conn, _params) do
    changeset = Admin.change_smart_contract(%SmartContract{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"smart_contract" => smart_contract_params}) do
    case Admin.create_smart_contract(smart_contract_params |> Map.merge(%{"abi" => Jason.decode!(smart_contract_params["abi"])})) do
      {:ok, smart_contract} ->
        conn
        |> put_flash(:info, "Smart contract created successfully.")
        |> redirect(to: Routes.admin_smart_contract_path(conn, :show, smart_contract))
      {:error, %Ecto.Changeset{} = changeset} ->
        IO.puts(changeset)
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    smart_contract = Admin.get_smart_contract!(id)
    render(conn, "show.html", smart_contract: smart_contract)
  end

  def edit(conn, %{"id" => id}) do
    smart_contract = Admin.get_smart_contract!(id)
    changeset = Admin.change_smart_contract(smart_contract)
    render(conn, "edit.html", smart_contract: smart_contract, changeset: changeset)
  end

  def update(conn, %{"id" => id, "smart_contract" => smart_contract_params}) do
    smart_contract = Admin.get_smart_contract!(id)

    case Admin.update_smart_contract(smart_contract, smart_contract_params |> Map.merge(%{"abi" => Jason.decode!(smart_contract_params["abi"])})) do
      {:ok, smart_contract} ->
        conn
        |> put_flash(:info, "Smart contract updated successfully.")
        |> redirect(to: Routes.admin_smart_contract_path(conn, :show, smart_contract))
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", smart_contract: smart_contract, changeset: changeset)
    end
  end

  def delete(conn, %{"id" => id}) do
    smart_contract = Admin.get_smart_contract!(id)
    {:ok, _smart_contract} = Admin.delete_smart_contract(smart_contract)

    conn
    |> put_flash(:info, "Smart contract deleted successfully.")
    |> redirect(to: Routes.admin_smart_contract_path(conn, :index))
  end
end
