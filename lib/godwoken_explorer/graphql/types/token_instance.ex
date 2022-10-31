defmodule GodwokenExplorer.Graphql.Types.TokenInstance do
  use Absinthe.Schema.Notation

  object :token_instance do
    field :token_contract_address_hash, :hash_address, description: "Address hash foreign key."
    field :token_id, :decimal, description: "ID of the token."
    field :metadata, :json, description: "Token instance metadata."
    field :error, :string, description: "Error of fetching token instance."
  end
end
