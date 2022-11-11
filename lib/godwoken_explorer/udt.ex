defmodule GodwokenExplorer.UDT do
  @moduledoc """
  Layer2 UDT list.

  """
  use GodwokenExplorer, :schema

  import GodwokenRPC.Util, only: [hex_to_number: 1, script_to_hash: 1, import_timestamps: 0]

  alias GodwokenExplorer.Chain.{Hash, Import}

  alias GodwokenExplorer.TokenTransfer
  alias GodwokenExplorer.Account.{UDTBalance}

  import Ecto.Query

  @default_ckb_account_id 1

  @typedoc """
    * `id` - Udt id is same with account id.
    * `decimal` - Set in contract.
    * `symbol` - [UAN](https://github.com/nervosnetwork/rfcs/pull/335).
    * `name` - [UAN](https://github.com/nervosnetwork/rfcs/pull/335).
    * `icon` - UDT icon url.
    * `supply` - Total supply.
    * `type_script` - Layer1 udt's type script.
    * `description` - UDT's description.
    * `official_site` - UDT's official site.
    * `value` - UDT's price * supply.
    * `price` - UDT's market price.
    * `bridge_account_id` - If udt type is bridge, it must have a native proxy account on layer2.
    * `contract_address_hash` - For type is native, it have contract address hash.
    * `type` - Bridge means from layer1;Native means layer2 contract.
    * `eth_type` - EVM token type.
    * `skip_metadata` - Skip metadata fetch.
    * `is_fetched` - Fetched metadata or not.
  """
  @type t :: %__MODULE__{
          id: non_neg_integer(),
          decimal: non_neg_integer(),
          symbol: String.t(),
          name: String.t(),
          icon: String.t(),
          supply: Hash.Full.t(),
          type_script: non_neg_integer(),
          description: non_neg_integer(),
          official_site: non_neg_integer(),
          value: Decimal.t(),
          price: Decimal.t(),
          bridge_account_id: non_neg_integer(),
          contract_address_hash: Hash.Address.t(),
          type: String.t(),
          eth_type: String.t(),
          skip_metadata: boolean(),
          is_fetched: boolean(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  @derive {Jason.Encoder, except: [:__meta__]}
  @primary_key {:id, :integer, autogenerate: false}
  schema "udts" do
    field(:decimal, :integer)
    field(:name, :string)
    field(:symbol, :string)
    field(:icon, :string)
    field(:supply, :decimal)
    field(:type_script, :map)
    field(:script_hash, Hash.Full)
    field(:description, :string)
    field(:official_site, :string)
    field(:value, :decimal)
    field(:price, :decimal)
    field(:bridge_account_id, :integer)
    field(:contract_address_hash, Hash.Address)
    field(:type, Ecto.Enum, values: [:bridge, :native])
    field(:eth_type, Ecto.Enum, values: [:erc20, :erc721, :erc1155])
    field(:skip_metadata, :boolean)
    field(:is_fetched, :boolean)

    belongs_to(:account, Account,
      foreign_key: :bridge_account_id,
      references: :id,
      define_field: false
    )

    field(:holders_count, :integer, virtual: true)
    field(:token_type_count, :integer, virtual: true)

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
      :contract_address_hash,
      :bridge_account_id,
      :eth_type,
      :skip_metadata,
      :is_fetched
    ])
    |> unique_constraint(:id, name: :udts_pkey)
    |> unique_constraint(:contract_address_hash, name: :udts_contract_address_hash_index)
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

  defmacrop dyn_cub_condition(udt) do
    quote bind_quoted: [udt: udt] do
      if not is_nil(udt) do
        if udt.type == :native do
          dynamic(
            [c],
            c.token_contract_address_hash == ^udt.contract_address_hash and c.value > 0
          )
        else
          false
        end
      else
        false
      end
    end
  end

  defmacrop dyn_cbub_condition(udt) do
    quote bind_quoted: [udt: udt] do
      if not is_nil(udt) do
        if udt.type == :bridge do
          dynamic(
            [c],
            c.udt_id == ^udt.id and c.value > 0
          )
        else
          false
        end
      else
        false
      end
    end
  end

  defmacrop dyn_mapping_udt_condtion(udt) do
    quote bind_quoted: [udt: udt] do
      if not is_nil(udt) do
        conditions =
          if udt.type == :native do
            dynamic([u], u.bridge_account_id == ^udt.id)
          else
            false
          end

        if udt.type == :bridge do
          dynamic([u], u.id == ^udt.bridge_account_id or ^conditions)
        else
          conditions
        end
      else
        false
      end
    end
  end

  def find_mapping_udt(udt) do
    mapping_udt_conditions = dyn_mapping_udt_condtion(udt)
    mapping_udt_query = from(u in UDT, where: ^mapping_udt_conditions)
    Repo.one(mapping_udt_query)
  end

  def count_holder(udt) do
    mapping_udt = find_mapping_udt(udt)

    cub1_conditions = dyn_cub_condition(udt)
    cub2_conditions = dyn_cub_condition(mapping_udt)

    cu_query =
      from(cub in CurrentUDTBalance,
        where: ^cub1_conditions,
        or_where: ^cub2_conditions
      )
      |> select([cub], %{address_hash: cub.address_hash})

    cbub1_conditions = dyn_cbub_condition(udt)
    cbub2_conditions = dyn_cbub_condition(mapping_udt)

    cbu_query =
      from(cbub in CurrentBridgedUDTBalance,
        where: ^cbub1_conditions,
        or_where: ^cbub2_conditions
      )
      |> select([cbub], %{address_hash: cbub.address_hash})

    from(cb in subquery(union_all(cu_query, ^cbu_query)))
    |> distinct([cb], cb.address_hash)
    |> Repo.aggregate(:count)
  end

  # minted count by token transfer from "0x0000000000000000000000000000000000000000"
  # TODO: add cache, materialize view?
  def minted_count(udt) do
    if udt do
      contract_address_hash = udt.contract_address_hash
      minted_burn_address_hash = UDTBalance.minted_burn_address_hash()

      created_count =
        from(tt in TokenTransfer)
        |> where([tt], tt.token_contract_address_hash == ^contract_address_hash)
        |> where([tt], tt.from_address_hash == ^minted_burn_address_hash)
        |> Repo.aggregate(:count)

      burned_count =
        from(tt in TokenTransfer)
        |> where([tt], tt.token_contract_address_hash == ^contract_address_hash)
        |> where([tt], tt.to_address_hash == ^minted_burn_address_hash)
        |> Repo.aggregate(:count)

      max(created_count - burned_count, 0)
    else
      0
    end
  end

  def get_decimal(id) do
    case from(u in UDT, where: u.id == ^id) |> Repo.one() do
      nil ->
        0

      %UDT{decimal: decimal} ->
        decimal
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
          Account.manual_create_account!(@default_ckb_account_id)
          FastGlobal.put(:ckb_account_id, @default_ckb_account_id)
          @default_ckb_account_id
      end
    end
  end

  def ckb_bridge_account_id do
    if FastGlobal.get(:ckb_bridge_account_id) do
      FastGlobal.get(:ckb_bridge_account_id)
    else
      with %__MODULE__{bridge_account_id: bridge_account_id} when not is_nil(bridge_account_id) <-
             Repo.get(__MODULE__, ckb_account_id()) do
        FastGlobal.put(:ckb_bridge_account_id, bridge_account_id)

        bridge_account_id
      else
        _ ->
          nil
      end
    end
  end

  # TODO unused function
  def find_by_name_or_token(keyword) do
    from(u in UDT,
      where:
        fragment("lower(?)", u.name) == ^keyword or fragment("lower(?)", u.symbol) == ^keyword
    )
    |> Repo.all()
    |> List.first()
  end

  def get_by_contract_address(contract_address) do
    case from(u in UDT, where: u.contract_address_hash == ^contract_address) |> Repo.one() do
      %UDT{} = udt ->
        udt

      nil ->
        %{id: nil, name: "", decimal: 0, symbol: ""}
    end
  end

  def list_address_by_udt_id(nil) do
    []
  end

  def list_address_by_udt_id(udt_id) do
    case Repo.get(UDT, udt_id) do
      %UDT{type: :bridge} = udt ->
        %Account{script_hash: script_hash} = Repo.get(Account, udt.id)

        with %{bridge_account_id: bridge_account_id} when bridge_account_id != nil <- udt,
             %Account{eth_address: eth_address} <- Repo.get(Account, udt.bridge_account_id) do
          [script_hash, eth_address]
        else
          _ -> [script_hash, nil]
        end

      %UDT{type: :native} = udt ->
        %Account{eth_address: eth_address} = Repo.get(Account, udt.id)

        with bridge_account when bridge_account != nil <-
               Repo.get_by(UDT, bridge_account_id: udt_id),
             %Account{script_hash: script_hash} <- Repo.get(Account, bridge_account.id) do
          [script_hash, eth_address]
        else
          _ -> [nil, eth_address]
        end

      nil ->
        []
    end
  end

  # Refactor: use contract module's eth_call_request method
  def eth_call_total_supply(contract_address) do
    method_sig = "0x18160DDD"

    case GodwokenRPC.eth_call(%{
           to: contract_address,
           data: method_sig
         }) do
      {:ok, hex_number} when hex_number != "0x" -> hex_to_number(hex_number)
      _ -> nil
    end
  end

  def eth_call_decimal(contract_address) do
    method_sig = "0x313CE567"

    case GodwokenRPC.eth_call(%{
           to: contract_address,
           data: method_sig
         }) do
      {:ok, hex_number} when hex_number != "0x" -> hex_to_number(hex_number)
      _ -> nil
    end
  end

  def eth_call_name(contract_address) do
    method_sig = "0x06FDDE03"

    case GodwokenRPC.eth_call(%{
           to: contract_address,
           gas: "0x7530",
           data: method_sig
         }) do
      {:ok, hex_name} ->
        ABI.decode(
          "name(string)",
          hex_name |> String.slice(2..-1) |> Base.decode16!(case: :lower)
        )
        |> List.first()

      _ ->
        ""
    end
  end

  def eth_call_symbol(contract_address) do
    method_sig = "0x95D89B41"

    case GodwokenRPC.eth_call(%{
           to: contract_address,
           data: method_sig
         }) do
      {:ok, hex_symbol} ->
        ABI.decode(
          "name(string)",
          hex_symbol |> String.slice(2..-1) |> Base.decode16!(case: :lower)
        )
        |> List.first()

      _ ->
        ""
    end
  end

  def is_erc721?(contract_address) do
    method_sig = "0x01ffc9a7"
    erc721_interface_id = "780e9d63"

    case GodwokenRPC.eth_call(%{
           to: contract_address,
           # gas: 30000
           gas: "0x7530",
           # 36 bytes
           data:
             method_sig <>
               erc721_interface_id <> "00000000000000000000000000000000000000000000000000000000"
         }) do
      {:ok, result} ->
        result == "0x0000000000000000000000000000000000000000000000000000000000000000"

      _ ->
        false
    end
  end

  def is_erc1155?(contract_address) do
    method_sig = "0x01ffc9a7"
    erc1155_interface_id = "4e2312e0"

    case GodwokenRPC.eth_call(%{
           to: contract_address,
           # gas: 30000
           gas: "0x7530",
           # 36 bytes
           data:
             method_sig <>
               erc1155_interface_id <> "00000000000000000000000000000000000000000000000000000000"
         }) do
      {:ok, result} ->
        result == "0x0000000000000000000000000000000000000000000000000000000000000000"

      _ ->
        false
    end
  end

  def list_bridge_token_by_udt_script_hashes(udt_script_hashes) do
    from(u in UDT,
      where: u.type == :bridge and u.script_hash in ^udt_script_hashes,
      select: {fragment("'0x' || encode(?, 'hex')", u.script_hash), u.id}
    )
    |> Repo.all()
  end

  def filter_not_exist_udts(udt_script_and_hashes) do
    udt_script_and_hashes = udt_script_and_hashes |> Enum.into(%{}, fn {k, v} -> {k, v} end)

    udt_script_hashes = udt_script_and_hashes |> Map.keys()

    exist_udt_script_hashes =
      from(u in UDT,
        where: u.type == :bridge and u.script_hash in ^udt_script_hashes,
        select: fragment("'0x' || encode(?, 'hex')", u.script_hash)
      )
      |> Repo.all()

    not_exist_udt_script_hashes = udt_script_hashes -- exist_udt_script_hashes
    Map.take(udt_script_and_hashes, not_exist_udt_script_hashes)
  end

  def import_from_github(url) do
    %{body: body} = HTTPoison.get!(url)

    udt_list = Jason.decode!(body)

    l2_udt_code_hash = Application.get_env(:godwoken_explorer, :l2_udt_code_hash)
    rollup_type_hash = Application.get_env(:godwoken_explorer, :rollup_type_hash)
    l1_udt_code_hash = Application.get_env(:godwoken_explorer, :l1_udt_code_hash)

    udt_params =
      udt_list
      |> Enum.map(fn %{
                       "erc20Info" => %{
                         "ethAddress" => eth_address,
                         "sudtScriptArgs" => l1_udt_script_args
                       },
                       "info" => %{"decimals" => decimal, "name" => name, "symbol" => symbol}
                     } = udt_info ->
        l1_udt_script = %{
          "code_hash" => l1_udt_code_hash,
          "hash_type" => "type",
          "args" => l1_udt_script_args
        }

        l1_script_hash = script_to_hash(l1_udt_script)

        l2_account_script = %{
          "code_hash" => l2_udt_code_hash,
          "hash_type" => "type",
          "args" => rollup_type_hash <> String.slice(l1_script_hash, 2..-1)
        }

        l2_script_hash = script_to_hash(l2_account_script)

        with %Account{id: bridge_account_id, eth_address: eth_address} <-
               Repo.get_by(Account, eth_address: eth_address),
             %Account{id: udt_id} <- Repo.get_by(Account, script_hash: l2_script_hash) do
          %{
            id: udt_id,
            name: udt_info["displayName"] || name,
            symbol: udt_info["UAN"] || symbol,
            decimal: decimal,
            bridge_account_id: bridge_account_id,
            script_hash: l1_script_hash,
            type_script: l1_udt_script,
            eth_type: :erc20,
            contract_address_hash: eth_address
          }
        end
      end)
      |> Enum.reject(&is_nil(&1))

    native_udt_params =
      udt_params
      |> Enum.map(fn udt ->
        %{
          id: udt.bridge_account_id,
          name: udt.name,
          symbol: udt.symbol,
          contract_address_hash: udt.contract_address_hash,
          type: :native,
          eth_type: :erc20
        }
      end)

    Import.insert_changes_list(
      udt_params |> Enum.map(fn udt -> Map.delete(udt, :contract_address_hash) end),
      for: UDT,
      timestamps: import_timestamps(),
      on_conflict: {:replace, [:name, :symbol, :eth_type, :bridge_account_id, :updated_at]},
      conflict_target: :id
    )

    Import.insert_changes_list(
      native_udt_params,
      for: UDT,
      timestamps: import_timestamps(),
      on_conflict: {:replace, [:name, :symbol, :eth_type, :updated_at]},
      conflict_target: :id
    )
  end

  def async_fetch_total_supply(contract_address_hash) do
    %{address_hash: contract_address_hash}
    |> GodwokenIndexer.Worker.UpdateUDTInfo.new()
    |> Oban.insert()
  end
end
