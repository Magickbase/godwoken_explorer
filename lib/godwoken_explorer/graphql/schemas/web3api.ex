defmodule GodwokenExplorer.Graphql.Schemas.Web3API do
  use Absinthe.Schema
  import_types(Absinthe.Type.Custom)
  import_types(GodwokenExplorer.Graphql.Types.Custom.JSON)
  import_types(GodwokenExplorer.Graphql.Types.Custom.UUID4)
  import_types(GodwokenExplorer.Graphql.Types.Custom.Money)

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
  import_types(GodwokenExplorer.Graphql.Types.AccountUDT)
  import_types(GodwokenExplorer.Graphql.Types.Log)
  import_types(GodwokenExplorer.Graphql.Types.Tracker)

  query do
    import_fields(:web3_account_udt_querys)
    import_fields(:web3_transaction_querys)
    import_fields(:web3_token_transfer_querys)
    import_fields(:web3_smart_contract_querys)
    import_fields(:web3_log_querys)
    import_fields(:web3_tracker_querys)
  end

  # mutation do
  # end

  # subscription do
  # end
end
