defmodule GodwokenExplorer.Graphql.Schemas.Dashboard do
  use Absinthe.Schema
  import_types(Absinthe.Type.Custom)
  import_types(GodwokenExplorer.Graphql.Types.Custom.JSON)
  import_types(GodwokenExplorer.Graphql.Types.Custom.UUID4)
  import_types(GodwokenExplorer.Graphql.Types.Custom.Money)

  query do
  end

  # mutation do
  # end

  # subscription do
  # end
end
