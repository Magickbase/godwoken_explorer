defmodule GodwokenExplorer.TokenInstanceFactory do
  alias GodwokenExplorer.TokenInstance

  defmacro __using__(_opts) do
    quote do
      def token_instance_factory do
        %TokenInstance{
          token_contract_address_hash: address_hash(),
          token_id: Enum.random(1..100_000) |> Decimal.new(),
          metadata: %{
            "attributes" => [
              %{"trait_type" => "background", "value" => "Red"},
              %{"trait_type" => "skin", "value" => "Spirit"},
              %{"trait_type" => "clothes", "value" => "StrawPoncho"},
              %{"trait_type" => "face", "value" => "Shyness"},
              %{"trait_type" => "headdress", "value" => "Tengu Mask"}
            ],
            "description" => "1,000 unique, randomly-generated Yokaiswap NFTs.",
            "id" => 0,
            "image" => "ipfs://Qmbns2AEEZ8TurmJHSt6RZ6KsQyrGG42Hay1wNY6RsQtE3/yokaiswapnft0.png",
            "name" => "Yokaiswap NFTs #0"
          }
        }
      end
    end
  end
end
