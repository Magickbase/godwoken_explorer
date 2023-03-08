defmodule GodwokenExplorer.ERC721TokenFactory do
  alias GodwokenExplorer.ERC721Token

  defmacro __using__(_opts) do
    quote do
      def erc721_token_factory do
        %ERC721Token{
          address_hash: address_hash(),
          token_contract_address_hash: address_hash(),
          block_number: block_number(),
          token_id: token_id(),
        }
      end
    end
  end
end
