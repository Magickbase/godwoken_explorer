defmodule GodwokenExplorer.Log do
  use GodwokenExplorer, :schema

  alias GodwokenExplorer.Chain.{Hash, Data}

  @required_attrs ~w(address_hash data block_hash index transaction_hash)a
  @optional_attrs ~w(first_topic second_topic third_topic fourth_topic block_number)a

  @derive {Jason.Encoder, except: [:__meta__]}
  @primary_key false
  schema "logs" do
    field(:data, Data)
    field(:first_topic, :string)
    field(:second_topic, :string)
    field(:third_topic, :string)
    field(:fourth_topic, :string)
    field(:index, :integer, primary_key: true)
    field(:block_number, :integer)
    field(:address_hash, Hash.Address)

    belongs_to(:transaction, Transaction,
      foreign_key: :transaction_hash,
      primary_key: true,
      references: :hash,
      type: Hash.Full
    )

    belongs_to(:block, Block,
      foreign_key: :block_hash,
      references: :hash,
      type: Hash.Full
    )

    timestamps()
  end

  @doc """
  `address_hash` and `transaction_hash` are converted to `t:Explorer.Chain.Hash.t/0`.  The allowed values for `type`
  are currently unknown, so it is left as a `t:String.t/0`.

      iex> changeset =GodwokenExplorer.Chain.Log.changeset(
      ...>   %Explorer.Chain.Log{},
      ...>   %{
      ...>     address_hash: "0x8bf38d4764929064f2d4d3a56520a76ab3df415b",
      ...>     block_hash: "0xf6b4b8c88df3ebd252ec476328334dc026cf66606a84fb769b3d3cbccc8471bd",
      ...>     data: "0x000000000000000000000000862d67cb0773ee3f8ce7ea89b328ffea861ab3ef",
      ...>     first_topic: "0x600bcf04a13e752d1e3670a5a9f1c21177ca2a93c6f5391d4f1298d098097c22",
      ...>     fourth_topic: nil,
      ...>     index: 0,
      ...>     second_topic: nil,
      ...>     third_topic: nil,
      ...>     transaction_hash: "0x53bd884872de3e488692881baeec262e7b95234d3965248c39fe992fffd433e5",
      ...>     type: "mined"
      ...>   }
      ...> )
      iex> changeset.valid?
      true
      iex> changeset.changes.address_hash
      %Explorer.Chain.Hash{
        byte_count: 20,
        bytes: <<139, 243, 141, 71, 100, 146, 144, 100, 242, 212, 211, 165, 101, 32, 167, 106, 179, 223, 65, 91>>
      }
      iex> changeset.changes.transaction_hash
      %Explorer.Chain.Hash{
        byte_count: 32,
        bytes: <<83, 189, 136, 72, 114, 222, 62, 72, 134, 146, 136, 27, 174, 236, 38, 46, 123, 149, 35, 77, 57, 101, 36,
                 140, 57, 254, 153, 47, 255, 212, 51, 229>>
      }
      iex> changeset.changes.type
      "mined"

  """
  def changeset(%__MODULE__{} = log, attrs \\ %{}) do
    log
    |> cast(attrs, @required_attrs)
    |> cast(attrs, @optional_attrs)
    |> validate_required(@required_attrs)
  end
end
