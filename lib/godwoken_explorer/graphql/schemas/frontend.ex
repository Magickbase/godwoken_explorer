defmodule GodwokenExplorer.Graphql.Schemas.Frontend do
  use Absinthe.Schema
  import_types(Absinthe.Type.Custom)
  import_types(GodwokenExplorer.Graphql.Types.Custom.JSON)
  import_types(GodwokenExplorer.Graphql.Types.Custom.UUID4)
  import_types(GodwokenExplorer.Graphql.Types.Custom.Money)

  import_types(GodwokenExplorer.Graphql.Types.Common)
  import_types(GodwokenExplorer.Graphql.Types.Block)
  import_types(GodwokenExplorer.Graphql.Types.Transaction)
  import_types(GodwokenExplorer.Graphql.Types.Statistic)
  import_types(GodwokenExplorer.Graphql.Types.Account)
  import_types(GodwokenExplorer.Graphql.Types.SmartContract)
  import_types(GodwokenExplorer.Graphql.Types.TokenTransfer)
  import_types(GodwokenExplorer.Graphql.Types.Polyjuice)
  import_types(GodwokenExplorer.Graphql.Types.UDT)
  import_types(GodwokenExplorer.Graphql.Types.Search)
  import_types(GodwokenExplorer.Graphql.Types.History)

  def middleware(middleware, _field, _object) do
    middleware
  end

  query do
    import_fields(:block_querys)
    import_fields(:transaction_querys)
    import_fields(:statistic_querys)
    import_fields(:account_querys)
    import_fields(:token_transfer_querys)
    import_fields(:search_querys)
    import_fields(:history_querys)
  end

  # mutation do
  # end

  # subscription do
  # end
end
