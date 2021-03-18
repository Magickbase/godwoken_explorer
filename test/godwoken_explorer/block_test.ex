defmodule GodwokenExplorer.BlockTest do
  use GodwokenExplorer.DataCase

  alias Ecto.Changeset
  alias GodwokenExplorer.Block

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

  describe "create/1" do
    test "create success" do
    end

    test "create failed" do
    end
  end

  describe "find_by_number_or_hash/1" do
    test "find by number" do
    end

    test "find by hash" do
    end

    test "find no record" do
    end
  end

  describe "get_next_number/0" do
    test "with alreday exist record" do
    end

    test "with empty record" do
    end
  end

  describe "latest_10_records/0" do
     test "with cache" do
     end

     test "when no cache" do
     end
  end

  describe "transactions_count_per_second" do
    test "with exist records" do
    end

    test "with empty records" do
    end
  end

  describe "update_blocks_finalized" do
    test "with updated blocks" do
    end

    test "no blocks updated" do
    end
  end

  describe "bind_l1_l2_block/3" do
    test "bind succeed" do
    end

    test "no block need bind" do
    end
  end
end
