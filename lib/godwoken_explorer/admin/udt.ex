defmodule GodwokenExplorer.Admin.UDT do
  @moduledoc """
  The Admin context.
  """

  import Ecto.Query, warn: false
  alias GodwokenExplorer.Repo
  import Torch.Helpers, only: [sort: 1, paginate: 4]
  import Filtrex.Type.Config

  # alias GodwokenExplorer.Admin.SmartContract
  alias GodwokenExplorer.UDT

  @pagination [page_size: 15]
  @pagination_distance 5

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
  def get_udt!(id), do: UDT |> preload(:account) |> Repo.get!(id)

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

  defp filter_config(:udts) do
    defconfig do
      text(:name)
      text(:symbol)
      text(:script_hash)
      text(:contract_address_hash)
    end
  end
end
