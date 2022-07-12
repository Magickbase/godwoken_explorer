defmodule GodwokenExplorerWeb.Admin.UDTController do
  use GodwokenExplorerWeb, :controller

  alias GodwokenExplorer.Admin.UDT, as: Admin
  alias GodwokenExplorer.{Account, Chain, Repo, UDT}

  plug(:put_root_layout, {GodwokenExplorerWeb.LayoutView, "torch.html"})
  plug(:put_layout, false)

  def index(conn, params) do
    case Admin.paginate_udts(params) do
      {:ok, assigns} ->
        render(conn, "index.html", assigns)

      error ->
        conn
        |> put_flash(:error, "There was an error rendering Udts. #{inspect(error)}")
        |> redirect(to: Routes.admin_udt_path(conn, :index))
    end
  end

  def new(conn, _params) do
    changeset = Admin.change_udt(%UDT{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"udt" => udt_params}) do
    udt_id =
      with {:ok, address_hash} <-
             Chain.string_to_address_hash(udt_params["contract_address_hash"]),
           %Account{id: udt_id} <- Repo.get_by(Account, eth_address: address_hash) do
        udt_id
      end

    udt_params =
      if udt_params["type"] == "native" do
        decimal = UDT.eth_call_decimal(udt_params["contract_address_hash"])
        total_supply = UDT.eth_call_total_supply(udt_params["contract_address_hash"])

        udt_params
        |> Map.merge(%{"id" => udt_id, "decimal" => decimal, "supply" => total_supply})
      else
        %Account{eth_address: eth_address} = Repo.get(Account, udt_id)
        decimal = UDT.eth_call_decimal(eth_address)
        total_supply = UDT.eth_call_total_supply(eth_address)

        udt_params
        |> Map.merge(%{
          "bridge_account_id" => udt_id,
          "decimal" => decimal,
          "supply" => total_supply
        })
      end

    case Admin.create_udt(udt_params) do
      {:ok, udt} ->
        conn
        |> put_flash(:info, "Udt created successfully.")
        |> redirect(to: Routes.admin_udt_path(conn, :show, udt))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    udt = Admin.get_udt!(id)
    render(conn, "show.html", udt: udt)
  end

  def edit(conn, %{"id" => id}) do
    udt = Admin.get_udt!(id)
    changeset = Admin.change_udt(udt)

    render(conn, "edit.html", udt: udt, changeset: changeset)
  end

  def update(conn, %{"id" => id, "udt" => udt_params}) do
    udt = Admin.get_udt!(id)

    udt_params =
      if udt_params["type"] == "native" do
        decimal = UDT.eth_call_decimal(to_string(udt.contract_address_hash))
        total_supply = UDT.eth_call_total_supply(to_string(udt.contract_address_hash))

        udt_params
        |> Map.merge(%{"decimal" => decimal, "supply" => total_supply})
      else
        %Account{eth_address: eth_address} = Repo.get(Account, udt.bridge_account_id)
        decimal = UDT.eth_call_decimal(eth_address)
        total_supply = UDT.eth_call_total_supply(eth_address)

        udt_params
        |> Map.merge(%{
          "decimal" => decimal,
          "supply" => total_supply
        })
      end

    case Admin.update_udt(udt, udt_params) do
      {:ok, udt} ->
        conn
        |> put_flash(:info, "Udt updated successfully.")
        |> redirect(to: Routes.admin_udt_path(conn, :show, udt))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", udt: udt, changeset: changeset)
    end
  end
end
