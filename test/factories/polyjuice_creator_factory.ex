defmodule GodwokenExplorer.PolyjuiceCreatorFactory do
  alias GodwokenExplorer.PolyjuiceCreator

  defmacro __using__(_opts) do
    quote do
      def polyjuice_creator_factory do
        %PolyjuiceCreator{
          code_hash: "0x07521d0aa8e66ef441ebc31204d86bb23fc83e9edc58c19dbb1b0ebe64336ec0",
          script_args:
            "0x702359ea7f073558921eb50d8c1c77e92f760c8f8656bde4995f26b8963e2dd848a466ed98a517bab6158209bd54c6b29281b733",
          hash_type: "type",
          transaction: build(:polyjuice_creator_tx)
        }
      end
    end
  end
end
