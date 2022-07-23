defmodule GodwokenExplorer.UtilFactory do
  alias GodwokenExplorer.Chain.{Hash, Data}

  defmacro __using__(_opts) do
    quote do
      def address_hash do
        {:ok, address_hash} =
          "address_hash"
          |> sequence(& &1)
          |> Hash.Address.cast()

        if to_string(address_hash) == "0x0000000000000000000000000000000000000000" do
          address_hash()
        else
          address_hash
        end
      end

      def block_hash do
        {:ok, block_hash} =
          "block_hash"
          |> sequence(& &1)
          |> Hash.Full.cast()

        if to_string(block_hash) ==
             "0x0000000000000000000000000000000000000000000000000000000000000000" do
          block_hash()
        else
          block_hash
        end
      end

      def transaction_hash do
        {:ok, transaction_hash} =
          "transaction_hash"
          |> sequence(& &1)
          |> Hash.Full.cast()

        transaction_hash
      end

      def udt_script_hash do
        {:ok, udt_script_hssh} =
          "udt_script_hash"
          |> sequence(& &1)
          |> Hash.Full.cast()

        udt_script_hssh
      end

      def transaction_input do
        data(:transaction_input)
      end

      def data(sequence_name) do
        unpadded =
          sequence_name
          |> sequence(& &1)
          |> Integer.to_string(16)

        unpadded_length = String.length(unpadded)

        padded =
          case rem(unpadded_length, 2) do
            0 -> unpadded
            1 -> "0" <> unpadded
          end

        {:ok, data} = Data.cast("0x#{padded}")

        data
      end

      def block_number do
        sequence("block_number", & &1)
      end
    end
  end
end
