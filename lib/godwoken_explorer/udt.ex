defmodule GodwokenExplorer.UDT do
  use GodwokenExplorer, :schema

  import GodwokenRPC.Util, only: [hex_to_number: 1]

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
    field(:bridge_account_eth_address, :binary, virtual: true)
    field(:type, Ecto.Enum, values: [:bridge, :native])

    belongs_to(:account, Account,
      foreign_key: :bridge_account_id,
      references: :id,
      define_field: false
    )

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
      :bridge_account_eth_address,
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

  def ckb_account_id do
    ckb_script_hash = Application.get_env(:godwoken_explorer, :ckb_token_script_hash)

    if FastGlobal.get(:ckb_account_id) do
      FastGlobal.get(:ckb_account_id)
    else
      with %__MODULE__{id: id} <- Repo.get_by(__MODULE__, script_hash: ckb_script_hash) do
        FastGlobal.put(:ckb_account_id, id)
        id
      else
        _ ->
          {:ok, id} = Account.find_or_create_udt_account!(nil, ckb_script_hash)
          FastGlobal.put(:ckb_account_id, id)
          id
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

  def get_by_contract_address(contract_address) do
    with %Account{id: id} <- Account |> Repo.get_by(eth_address: contract_address),
         %UDT{} = udt <-
           from(u in UDT, where: u.id == ^id or u.bridge_account_id == ^id) |> Repo.one() do
      udt
    else
      _ ->
        %{id: nil, name: "", decimal: 0, symbol: ""}
    end
  end

  def eth_call_total_supply(contract_address) do
    total_supply_method = "0x18160DDD"

    case GodwokenRPC.eth_call(%{
           to: contract_address,
           data: total_supply_method
         }) do
      {:ok, hex_number} -> hex_to_number(hex_number)
      _ -> 0
    end
  end

  def eth_call_decimal(contract_address) do
    decimals_method = "0x313CE567"

    case GodwokenRPC.eth_call(%{
           to: contract_address,
           data: decimals_method
         }) do
      {:ok, hex_number} -> hex_to_number(hex_number)
      _ -> 8
    end
  end

  def list_address_by_udt_id(udt_id) do
    case Repo.get(UDT, udt_id) do
      %UDT{type: :bridge} = udt ->
        %Account{short_address: short_address} = Repo.get(Account, udt.id)

        with %{bridge_account_id: bridge_account_id} when bridge_account_id != nil <- udt,
             %Account{eth_address: eth_address} <- Repo.get(Account, udt.bridge_account_id) do
          [short_address, eth_address]
        else
          _ -> [short_address]
        end

      %UDT{type: :native} = udt ->
        %Account{eth_address: eth_address} = Repo.get(Account, udt.id)
        [eth_address]

      nil ->
        []
    end
  end
end
