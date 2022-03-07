defmodule GodwokenExplorer.Admin do
  @moduledoc """
  The Admin context.
  """

  import Ecto.Query, warn: false
  alias GodwokenExplorer.Repo
  import Torch.Helpers, only: [sort: 1, paginate: 4]
  import Filtrex.Type.Config

  # alias GodwokenExplorer.Admin.SmartContract
  alias GodwokenExplorer.SmartContract

  @pagination [page_size: 15]
  @pagination_distance 5

  @doc """
  Paginate the list of smart_contracts using filtrex
  filters.

  ## Examples

      iex> list_smart_contracts(%{})
      %{smart_contracts: [%SmartContract{}], ...}
  """
  @spec paginate_smart_contracts(map) :: {:ok, map} | {:error, any}
  def paginate_smart_contracts(params \\ %{}) do
    params =
      params
      |> Map.put_new("sort_direction", "desc")
      |> Map.put_new("sort_field", "inserted_at")

    {:ok, sort_direction} = Map.fetch(params, "sort_direction")
    {:ok, sort_field} = Map.fetch(params, "sort_field")

    with {:ok, filter} <-
           Filtrex.parse_params(filter_config(:smart_contracts), params["smart_contract"] || %{}),
         %Scrivener.Page{} = page <- do_paginate_smart_contracts(filter, params) do
      {:ok,
       %{
         smart_contracts: page.entries,
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
      error -> {:error, error}
    end
  end

  defp do_paginate_smart_contracts(filter, params) do
    SmartContract
    |> Filtrex.query(filter)
    |> order_by(^sort(params))
    |> paginate(Repo, params, @pagination)
  end

  @doc """
  Returns the list of smart_contracts.

  ## Examples

      iex> list_smart_contracts()
      [%SmartContract{}, ...]

  """
  def list_smart_contracts do
    Repo.all(SmartContract)
  end

  @doc """
  Gets a single smart_contract.

  Raises `Ecto.NoResultsError` if the Smart contract does not exist.

  ## Examples

      iex> get_smart_contract!(123)
      %SmartContract{}

      iex> get_smart_contract!(456)
      ** (Ecto.NoResultsError)

  """
  def get_smart_contract!(id), do: Repo.get!(SmartContract, id)

  @doc """
  Creates a smart_contract.

  ## Examples

      iex> create_smart_contract(%{field: value})
      {:ok, %SmartContract{}}

      iex> create_smart_contract(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_smart_contract(attrs \\ %{}) do
    %SmartContract{}
    |> SmartContract.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a smart_contract.

  ## Examples

      iex> update_smart_contract(smart_contract, %{field: new_value})
      {:ok, %SmartContract{}}

      iex> update_smart_contract(smart_contract, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_smart_contract(%SmartContract{} = smart_contract, attrs) do
    smart_contract
    |> SmartContract.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a SmartContract.

  ## Examples

      iex> delete_smart_contract(smart_contract)
      {:ok, %SmartContract{}}

      iex> delete_smart_contract(smart_contract)
      {:error, %Ecto.Changeset{}}

  """
  def delete_smart_contract(%SmartContract{} = smart_contract) do
    Repo.delete(smart_contract)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking smart_contract changes.

  ## Examples

      iex> change_smart_contract(smart_contract)
      %Ecto.Changeset{source: %SmartContract{}}

  """
  def change_smart_contract(%SmartContract{} = smart_contract, attrs \\ %{}) do
    SmartContract.changeset(smart_contract, attrs)
  end

  defp filter_config(:smart_contracts) do
    defconfig do
      text(:name)
      text(:contract_source_code)
      # TODO add config for abi of type map
      number(:account_id)
    end
  end
end
