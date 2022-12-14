defmodule GodwokenExplorer.Address do
  @moduledoc """
  Eth address that not exist in godwoken chain.
  """
  use Ecto.Schema

  import Ecto.Changeset

  alias GodwokenExplorer.Chain.Hash
  alias GodwokenExplorer.Repo
  alias GodwokenExplorer.Counters.AddressTokenTransfersCounter

  @typedoc """
  *  `eth_address` - The address hash.
  *  `bit_alias` - .bit alias.
  *  `token_transfer_count` - The address cached token transfer count.
  """

  @type t :: %__MODULE__{
          eth_address: Hash.Address.t(),
          bit_alias: String.t(),
          token_transfer_count: Integer.t(),
          inserted_at: NaiveDateTime.t(),
          updated_at: NaiveDateTime.t()
        }

  @derive {Jason.Encoder, except: [:__meta__]}
  @primary_key {:eth_address, Hash.Address, autogenerate: false}
  schema "addresses" do
    field(:token_transfer_count, :integer)
    field(:bit_alias, :string)

    timestamps()
  end

  @doc false
  def changeset(address, attrs) do
    address
    |> cast(attrs, [:eth_address, :token_transfer_count, :bit_alias])
    |> validate_required([:eth_address])
  end

  def find_or_insert_from_hash(hash) do
    case Repo.get(__MODULE__, hash) do
      %__MODULE__{} = address ->
        {:ok, address}

      nil ->
        __MODULE__.changeset(%__MODULE__{}, %{eth_address: hash}) |> Repo.insert()
    end
  end

  def async_update_info(address) do
    Task.async(fn ->
      AddressTokenTransfersCounter.fetch(address)
    end)

    Task.async(fn ->
      with {:ok, account_alias} <-
             address.hash
             |> GodwokenExplorer.Bit.API.fetch_reverse_record_info() do
        __MODULE__.changeset(address, %{bit_alias: account_alias}) |> Repo.update()
      end
    end)
  end
end
