alias GodwokenExplorer.Repo
alias Ecto.Multi
alias GodwokenExplorer.{
  Account,
  Block,
  CheckInfo,
  ContractMethod,
  DepositHistory,
  DailyStat,
  Log,
  PendingTransaction,
  PolyjuiceCreator,
  Polyjuice,
  Repo,
  SmartContract,
  Transaction,
  TokenTransfer,
  UDT,
  Version,
  WithdrawalHistory,
  WithdrawalRequest
}

alias GodwokenExplorer.Graphql.{Sourcify}

alias GodwokenExplorer.Account.{CurrentUDTBalance, CurrentBridgedUDTBalance, UDTBalance}

alias GodwokenExplorer.Graphql.Workers.SmartContractRegister

import Ecto.{Query, Queryable, Changeset}
