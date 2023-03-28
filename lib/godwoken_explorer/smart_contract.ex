defmodule GodwokenExplorer.SmartContract do
  @moduledoc """
  The representation of a verified Smart Contract.

  "A contract in the sense of Solidity is a collection of code (its functions)
  and data (its state) that resides at a specific address on the Ethereum
  blockchain."
  http://solidity.readthedocs.io/en/v0.4.24/introduction-to-smart-contracts.html
  """
  use GodwokenExplorer, :schema

  alias GodwokenExplorer.Chain.Hash
  alias GodwokenExplorer.Chain.Cache.SmartContract, as: CacheSmartContract
  alias GodwokenExplorer.SmartContract
  alias GodwokenExplorer.Repo

  import Ecto.Query

  @typedoc """
  * `abi` - Contract abi.
  * `contract_source_code` - Contract code.
  * `name` - Contract name.
  * `constructor_arguments` - Contract constructor arguments.
  * `deployment_tx_hash` - Contract deployment at which transaction.
  * `compiler_version` - Contract compiler version.
  * `compiler_file_format` - Solidity or other.
  * `other_info` - Some info.
  * `ckb_balance` - SmartContract ckb balance.
  * `account_id` - The account foreign key.
  """
  @type t :: %__MODULE__{
          abi: list(map()),
          contract_source_code: String.t(),
          name: non_neg_integer() | nil,
          constructor_arguments: Hash.Address.t(),
          deployment_tx_hash: Hash.Address.t(),
          compiler_version: Hash.Address.t(),
          compiler_file_format: String.t(),
          other_info: String.t(),
          ckb_balance: Decimal.t(),
          account_id: Integer.t(),
          account: %Ecto.Association.NotLoaded{} | Account.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }
  @derive {Jason.Encoder, except: [:__meta__]}
  schema "smart_contracts" do
    field :abi, {:array, :map}
    field :contract_source_code, :string
    field :name, :string

    belongs_to(
      :account,
      Account,
      foreign_key: :account_id,
      references: :id,
      type: :integer
    )

    field :constructor_arguments, :binary
    field :deployment_tx_hash, Hash.Full
    field :compiler_version, :string
    field :compiler_file_format, :string
    field :other_info, :string
    field :ckb_balance, :decimal

    field :transaction_count, :integer, virtual: true
    field :eth_address, :binary, virtual: true

    field :sourcify_metadata, {:array, :map}

    timestamps()
  end

  defp base_fields() do
    GodwokenExplorer.SchemeUtils.base_fields_without_id(__MODULE__)
  end

  @doc false
  def changeset(smart_contract, attrs) do
    smart_contract
    |> cast(attrs, base_fields())
    |> validate_required([:account_id])
    |> unique_constraint(:account_id)
  end

  def reformat_abi(abi) do
    abi
    |> Enum.map(&map_abi/1)
    |> Map.new()
  end

  def account_ids do
    CacheSmartContract.get(:account_ids)
  end

  def cache_account_ids do
    account_ids = from(s in SmartContract, select: s.account_id) |> Repo.all()

    CacheSmartContract.set(:account_ids, account_ids)
  end

  def cache_abis() do
    from(sc in SmartContract)
    |> Repo.all()
    |> Enum.chunk_every(10)
    |> Enum.map(fn sm_cs ->
      sm_cs
      |> Task.async_stream(fn sm_c ->
        ConCache.put(:cache_sc, "contract_abi_#{sm_c.account_id}", sm_c.abi)

        {"contract_abi_#{sm_c.account_id}", sm_c.abi}
      end)
      |> Enum.to_list()
    end)
    |> List.flatten()
    |> Enum.into(%{})
  end

  def cache_abi(account_id) do
    result = ConCache.get(:cache_sc, "contract_abi_#{account_id}")

    if result do
      result
    else
      abi =
        from(sc in SmartContract, where: sc.account_id == ^account_id, select: sc.abi)
        |> Repo.one()

      ConCache.put(:cache_sc, "contract_abi_#{account_id}", abi)
      abi
    end
  end

  def creator_address(smart_contract) do
    if smart_contract.deployment_tx_hash != nil do
      from(t in Transaction,
        join: a in Account,
        on: a.id == t.from_account_id,
        where: t.hash == ^smart_contract.deployment_tx_hash,
        select: a.eth_address
      )
      |> limit(1)
      |> Repo.one()
    else
      nil
    end
  end

  defp map_abi(x) do
    case {x["name"], x["type"]} do
      {nil, "constructor"} -> {:constructor, x}
      {nil, "fallback"} -> {:fallback, x}
      {name, _} -> {name, x}
    end
  end
end
