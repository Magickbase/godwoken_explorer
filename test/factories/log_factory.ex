defmodule GodwokenExplorer.LogFactory do
  alias GodwokenExplorer.Log

  defmacro __using__(_opts) do
    quote do
      def log_factory do
        block = build(:block)

        %Log{
          address_hash: address_hash(),
          block: block,
          block_number: block.number,
          data: data(:log_data),
          first_topic: nil,
          fourth_topic: nil,
          index: sequence("log_index", & &1),
          second_topic: nil,
          third_topic: nil,
          transaction_hash: build(:transaction).eth_hash
        }
      end

      def approval_log_factory do
        block = build(:block)

        %Log{
          address_hash: address_hash(),
          block: block,
          block_number: block.number,
          data: data(:log_data),
          first_topic: "0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925",
          fourth_topic: nil,
          index: sequence("log_index", & &1),
          second_topic: parse_address(address_hash()),
          third_topic: parse_address(address_hash()),
          transaction_hash: build(:transaction).eth_hash
        }
      end

      def approval_all_log_factory do
        block = build(:block)

        %Log{
          address_hash: address_hash(),
          block: block,
          block_number: block.number,
          data: data(:log_data),
          first_topic: "0x17307eab39ab6107e8899845ad3d59bd9653f200f220920489ca2b5937696c31",
          fourth_topic: nil,
          index: sequence("log_index", & &1),
          second_topic: parse_address(address_hash()),
          third_topic: parse_address(address_hash()),
          transaction_hash: build(:transaction).eth_hash
        }
      end

      defp parse_address(address_hash) do
        "0x" <>
          (address_hash
           |> to_string()
           |> String.slice(2..-1)
           |> pad_heading(32, 0)
           |> Base.encode16(case: :lower))
      end
    end
  end
end
