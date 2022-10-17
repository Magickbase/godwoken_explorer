defmodule GodwokenExplorer.Graphql.Types.TokenInstance do
  use Absinthe.Schema.Notation

  object :token_instance do
    field(:token_contract_address_hash, :hash_address)
    field(:token_id, :decimal)
    field(:metadata, :json)
    field(:error, :string)
  end
end
