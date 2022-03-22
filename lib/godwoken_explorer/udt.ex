defmodule GodwokenExplorer.UDT do
  use GodwokenExplorer, :schema

  import Torch.Helpers, only: [sort: 1, paginate: 4]
  import Filtrex.Type.Config

  alias GodwokenExplorer.KeyValue

  @pagination [page_size: 15]
  @pagination_distance 5

  @derive {Jason.Encoder, except: [:__meta__]}
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
    field(:value, :decimal)
    field(:price, :decimal)
    field(:bridge_account_id, :integer)
    field :type, Ecto.Enum, values: [:bridge, :native]

    belongs_to(:account, Account, foreign_key: :id, references: :id, define_field: false)

    timestamps()
  end

  @doc false
  def changeset(udt, attrs) do
    udt
    |> cast(attrs, [
      :id,
      :name,
      :symbol,
      :decimal,
      :icon,
      :supply,
      :type_script,
      :script_hash,
      :description,
      :official_site,
      :type,
      :value,
      :bridge_account_id
    ])
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

  def get_decimal(id) do
    case from(u in UDT, where: u.id == ^id or u.bridge_account_id == ^id) |> Repo.one() do
      nil ->
        0

      %UDT{decimal: decimal} ->
        decimal
    end
  end

  def get_udt_contract_ids do
    bridge_query =
      from(u in UDT,
        where: u.type == :bridge and not is_nil(u.name),
        select: %{id: u.bridge_account_id}
      )

    native_query =
      from(u in UDT, where: u.type == :native and not is_nil(u.name), select: %{id: u.id})

    from(q in subquery(union_all(bridge_query, ^native_query))) |> Repo.all() |> Enum.map(& &1.id)
  end

  def get_contract_id(udt_account_id) do
    case Repo.get(UDT, udt_account_id) do
      %UDT{type: :bridge, bridge_account_id: bridge_account_id}
      when not is_nil(bridge_account_id) ->
        bridge_account_id

      _ ->
        udt_account_id
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

  def find_by_name_or_token(keyword) do
    from(u in UDT,
      where:
        fragment("lower(?)", u.name) == ^keyword or fragment("lower(?)", u.symbol) == ^keyword
    )
    |> Repo.all()
    |> List.first()
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

  # TODO: current will calculate all deposits and withdrawals, after can calculate by incrementation
  def refresh_supply do
    key_value = Repo.get_by(KeyValue, key: :last_udt_supply_at)
    start_time =
      if key_value != nil do
        key_value.value |> Timex.parse!("{ISO:Extended}")
      else
        nil
      end
    end_time = Timex.beginning_of_day(Timex.now())

    deposits = DepositHistory.group_udt_amount(start_time, end_time) |> Map.new()
    withdrawals = WithdrawalHistory.group_udt_amount(start_time, end_time) |> Map.new()
    udt_amounts = Map.merge(deposits, withdrawals, fn _k, v1, v2 -> D.add(v1, v2) end)
    udt_ids = udt_amounts |> Map.keys()

    Repo.transaction(fn ->
      from(u in UDT, where: u.id in ^udt_ids)
      |> Repo.all()
      |> Enum.each(fn u ->
        UDT.changeset(u, %{
          supply: udt_amounts |> Map.fetch!(u.id) |> Decimal.div(Integer.pow(10, u.decimal || 0))
        })
        |> Repo.update!()
      end)
      KeyValue.changeset(key_value, %{value: end_time |> Timex.format!("{ISO:Extended}")}) |> Repo.update!
    end)
  end

  def get_by_contract_address(contract_address) do
    with %Account{id: id} <- Account |> Repo.get_by(short_address: contract_address),
         %UDT{} = udt <-
           from(u in UDT, where: u.id == ^id or u.bridge_account_id == ^id) |> Repo.one() do
      udt
    else
      _ ->
        %{id: nil, name: "", decimal: 0, symbol: ""}
    end
  end
end
