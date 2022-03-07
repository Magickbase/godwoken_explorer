defmodule GodwokenExplorer.Graphql.Types.UDT do
  use Absinthe.Schema.Notation
  alias GodwokenExplorer.Graphql.Resolvers, as: Resolvers

  object :udt_querys do
    field :udt, :udt do
      arg :input, :udt_id_input
      resolve(&Resolvers.UDT.udt/3)
    end

    field :udts, list_of(:udt) do
      arg :input, :udt_input
      resolve(&Resolvers.UDT.udts/3)
    end
  end

  object :udt do
    field :id, :string
    field :decimal, :integer
    field :name, :string
    field :symbol, :string
    field :icon, :string
    field :supply, :decimal
    field :type_script, :json
    field :script_hash, :string
    field :description, :string
    field :official_site, :string
    field :value, :decimal
    field :price, :decimal
    field :bridge_account_id, :integer
    field :type, :udt_type
  end

  enum :udt_type do
    value :bridge
    value :native
  end

  input_object :udt_id_input do
    field :id, :string
  end

  input_object :udt_input do
    field :type, :udt_type
    import_fields :page_and_size_input
  end


end
