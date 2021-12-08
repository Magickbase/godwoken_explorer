defmodule GodwokenExplorer.UDT do
  use GodwokenExplorer, :schema

  import Torch.Helpers, only: [sort: 1, paginate: 4]
  import Filtrex.Type.Config

  @pagination [page_size: 15]
  @pagination_distance 5

  @primary_key {:id, :integer, autogenerate: false}
  schema "udts" do
    field(:decimal, :integer)
    field(:name, :string)
    field(:symbol, :string)
    field(:icon, :string)
    field(:supply, :decimal)
    field(:type_script, :map)
    field(:script_hash, :binary)
    field(:description, :string)
    field(:official_site, :string)
    field :type, Ecto.Enum, values: [:bridge, :native]

    timestamps()
  end

  @doc false
  def changeset(udt, attrs) do
    udt
    |> cast(attrs, [:id, :name, :symbol, :decimal, :icon, :supply, :type_script, :script_hash, :description, :official_site, :type])
    |> unique_constraint(:id, name: :udts_pkey)
  end

  def find_or_create_by(attrs) do
    case Repo.get(__MODULE__, attrs[:id]) do
      nil ->
        %__MODULE__{}
        |> changeset(attrs)
        |> Repo.insert()

      udt ->
        {:ok, udt}
    end
  end

  def count_holder(udt_id) do
    from(au in AccountUDT, where: au.udt_id == ^udt_id) |> Repo.aggregate(:count)
  end

  @spec paginate_udts(map) :: {:ok, map} | {:error, any}
  def paginate_udts(params \\ %{}) do
    params =
      params
      |> Map.put_new("sort_direction", "desc")
      |> Map.put_new("sort_field", "inserted_at")

    {:ok, sort_direction} = Map.fetch(params, "sort_direction")
    {:ok, sort_field} = Map.fetch(params, "sort_field")

    with {:ok, filter} <- Filtrex.parse_params(filter_config(:udts), params["udt"] || %{}),
         %Scrivener.Page{} = page <- do_paginate_udts(filter, params) do
      {:ok,
       %{
         udts: page.entries,
         page_number: page.page_number,
         page_size: page.page_size,
         total_pages: page.total_pages,
         total_entries: page.total_entries,
         distance: @pagination_distance,
         sort_field: sort_field,
         sort_direction: sort_direction
       }}
    else
      {:error, error} -> {:error, error}
    end
  end

  defp do_paginate_udts(filter, params) do
    UDT
    |> Filtrex.query(filter)
    |> order_by(^sort(params))
    |> paginate(Repo, params, @pagination)
  end

  @doc """
  Returns the list of udts.

  ## Examples

      iex> list_udts()
      [%UDT{}, ...]

  """
  def list_udts do
    Repo.all(UDT)
  end

  @doc """
  Gets a single udt.

  Raises `Ecto.NoResultsError` if the Udt does not exist.

  ## Examples

      iex> get_udt!(123)
      %UDT{}

      iex> get_udt!(456)
      ** (Ecto.NoResultsError)

  """
  def get_udt!(id), do: Repo.get!(UDT, id)

  @doc """
  Creates a udt.

  ## Examples

      iex> create_udt(%{field: value})
      {:ok, %UDT{}}

      iex> create_udt(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_udt(attrs \\ %{}) do
    %UDT{}
    |> UDT.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a udt.

  ## Examples

      iex> update_udt(udt, %{field: new_value})
      {:ok, %UDT{}}

      iex> update_udt(udt, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_udt(%UDT{} = udt, attrs) do
    udt
    |> UDT.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a UDT.

  ## Examples

      iex> delete_udt(udt)
      {:ok, %UDT{}}

      iex> delete_udt(udt)
      {:error, %Ecto.Changeset{}}

  """
  def delete_udt(%UDT{} = udt) do
    Repo.delete(udt)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking udt changes.

  ## Examples

      iex> change_udt(udt)
      %Ecto.Changeset{source: %UDT{}}

  """
  def change_udt(%UDT{} = udt, attrs \\ %{}) do
    UDT.changeset(udt, attrs)
  end

  def ckb_account_id do
    if FastGlobal.get(:ckb_account_id) do
      FastGlobal.get(:ckb_account_id)
    else
      with ckb_script_hash when is_binary(ckb_script_hash) <-
             Application.get_env(:godwoken_explorer, :ckb_token_script_hash),
           %__MODULE__{id: id} <- Repo.get_by(__MODULE__, script_hash: ckb_script_hash) do
        FastGlobal.put(:ckb_account_id, id)
        id
      else
        _ -> nil
      end
    end
  end

  def eth_account_id do
    if FastGlobal.get(:eth_account_id) do
      FastGlobal.get(:eth_account_id)
    else
      with eth_script_hash when is_binary(eth_script_hash) <-
             Application.get_env(:godwoken_explorer, :eth_token_script_hash),
           %__MODULE__{id: id} <- Repo.get_by(__MODULE__, script_hash: eth_script_hash) do
        FastGlobal.put(:eth_account_id, id)
        id
      else
        _ -> nil
      end
    end
  end

  defp filter_config(:udts) do
    defconfig do
      number(:decimal)
      text(:name)
      text(:symbol)
      text(:icon)
      # TODO add config for supply of type decimal
      # TODO add config for type_script of type map
      # TODO add config for script_hash of type binary
    end
  end
end
