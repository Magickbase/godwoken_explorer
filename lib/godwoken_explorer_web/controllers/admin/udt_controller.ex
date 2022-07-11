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
      with {:ok, address_hash} <- Chain.string_to_address_hash(udt_params["udt_address"]),
           %Account{id: udt_id} <- Repo.get_by(Account, eth_address: address_hash) do
        udt_id
      end

    udt_params =
      if udt_params["type"] == "native" do
        udt_params
        |> Map.merge(%{
          "bridge_account_id" => udt_id,
          "contract_address_hash" => udt_params["udt_address"]
        })
      else
        with {:ok, address_hash} <-
               Chain.string_to_address_hash(udt_params["contract_address_hash"]),
             %Account{id: id, type: :polyjuice_contract} <-
               Repo.get_by(Account, eth_address: address_hash) do
          udt_params
          |> Map.merge(%{"bridge_account_id" => id, "contract_address_hash" => address_hash})
        else
          _ -> udt_params |> Map.merge(%{"bridge_account_id" => nil})
        end
      end
      |> Map.merge(%{"id" => udt_id})

    udt_params =
      if udt_params["bridge_account_id"] != nil do
        %Account{eth_address: eth_address} = Repo.get(Account, udt_params["bridge_account_id"])

        udt_params =
          if udt_params["decimal"] == "" do
            decimal = UDT.eth_call_decimal(eth_address)
            udt_params |> Map.merge(%{"decimal" => decimal})
          else
            udt_params
          end

        if udt_params["supply"] == "" do
          supply = UDT.eth_call_total_supply(eth_address)
          udt_params |> Map.merge(%{"supply" => supply})
        else
          udt_params
        end
      else
        udt_params
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
        udt_params |> Map.merge(%{"bridge_account_id" => id})
      else
        with {:ok, address_hash} <-
               Chain.string_to_address_hash(udt_params["contract_address_hash"]),
             %Account{id: id, type: :polyjuice_contract} <-
               Repo.get_by(Account, eth_address: address_hash) do
          udt_params |> Map.merge(%{"bridge_account_id" => id})
        else
          _ -> udt_params |> Map.merge(%{"bridge_account_id" => nil})
        end
      end

    udt_params =
      if udt_params["bridge_account_id"] != nil do
        %Account{eth_address: eth_address} = Repo.get(Account, udt_params["bridge_account_id"])

        udt_params =
          if udt_params["decimal"] == "" do
            decimal = UDT.eth_call_decimal(eth_address)
            udt_params |> Map.merge(%{"decimal" => decimal})
          else
            udt_params
          end

        if udt_params["supply"] == "" do
          supply = UDT.eth_call_total_supply(eth_address)
          udt_params |> Map.merge(%{"supply" => supply})
        else
          udt_params
        end
      else
        udt_params
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
