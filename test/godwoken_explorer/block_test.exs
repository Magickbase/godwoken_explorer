defmodule GodwokenExplorer.BlockTest do
  use GodwokenExplorer.DataCase

  alias Ecto.Changeset
  alias GodwokenExplorer.{
    Block,
    Transaction
  }
  alias GodwokenExplorer.Chain.Cache.Blocks

  setup do
    ExMachina.Sequence.reset()
  end

  describe "changeset/2" do
    test "with valid attributes" do
      assert %Changeset{valid?: true} =
               :block
               |> build()
               |> Block.changeset(%{})
    end

    test "with invalid attributes" do
      changeset = %Block{} |> Block.changeset(%{timestamp: nil})
      refute(changeset.valid?)
    end
  end

  describe "create_block/1" do
    test "create success" do
      params_list = :block |> params_for()
      assert {:ok, %Block{}} = Block.create_block(params_list)
    end

    test "create failed" do
      params_list = :block |> params_for(%{timestamp: nil})
      assert {:error, %Ecto.Changeset{valid?: false}} = Block.create_block(params_list)
    end
  end

  describe "find_by_number_or_hash/1" do
    setup do
      insert(:block)

      :ok
    end

    test "find by number" do
      assert %Block{number: 100} =
        Block.find_by_number_or_hash(100)
    end

    test "find by hash" do
      assert %Block{hash: "0x10047c3a847ede67fdad6357e7bf0a017fdb1be3e437a675a742e268af39bc3d"} =
        Block.find_by_number_or_hash("0x10047c3a847ede67fdad6357e7bf0a017fdb1be3e437a675a742e268af39bc3d")
    end

    test "find no record" do
      refute(Block.find_by_number_or_hash(10))
    end
  end

  describe "get_next_number/0" do
    test "with alreday exist record" do
      insert(:block)
      assert 101 = Block.get_next_number()
    end

    test "with empty record" do
      assert 0 = Block.get_next_number()
    end
  end

  describe "latest_10_records/0" do
     test "when no cache" do
      insert_list(11, :block)
      assert %{number: 110} = Block.latest_10_records() |> List.first()
      assert %{number: 101} = Block.latest_10_records() |> List.last()
      assert 10 = Block.latest_10_records() |> Enum.count()
     end

     test "with cache" do
      build_list(11, :block) |> Enum.each(fn block ->
        Blocks.update(block)
      end)
      assert %{number: 110} = Block.latest_10_records() |> List.first()
      assert %{number: 101} = Block.latest_10_records() |> List.last()
      assert 10 = Block.latest_10_records() |> Enum.count()
     end
  end

  describe "transactions_count_per_second" do
    test "with exist records" do
      insert_list(10, :block)
      assert 1.1 = Block.transactions_count_per_second()
    end

    test "with empty records" do
      assert 0.0 = Block.transactions_count_per_second()
    end
  end

  describe "update_blocks_finalized" do
    test "with updated blocks" do
      insert_list(10, :block)
      Block.update_blocks_finalized(105)
      assert 6 = from(b in Block, where: b.status == :finalized) |> Repo.aggregate(:count)
      assert 6 = from(t in Transaction, where: t.status == :finalized) |> Repo.aggregate(:count)
    end

    test "no blocks updated" do
      insert_list(10, :block)
      Block.update_blocks_finalized(99)
      assert 0 = from(b in Block, where: b.status == :finalized) |> Repo.aggregate(:count)
      assert 0 = from(t in Transaction, where: t.status == :finalized) |> Repo.aggregate(:count)
    end
  end

  describe "bind_l1_l2_block/3" do
    test "bind succeed" do
      insert(:block, %{layer1_block_number: nil, layer1_tx_hash: nil})
      assert 3100 = Block.bind_l1_l2_block(100, 3100, "0x01")
      assert %Block{layer1_block_number: 3100, layer1_tx_hash: "0x01"} = Repo.get_by(Block, number: 100)
    end

    test "no block need bind" do
      insert(:block, %{layer1_block_number: nil, layer1_tx_hash: nil})
      refute(Block.bind_l1_l2_block(101, 3100, "0x01"))
      assert %Block{layer1_block_number: nil, layer1_tx_hash: nil} = Repo.get_by(Block, number: 100)
    end
  end
end
