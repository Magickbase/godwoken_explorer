defmodule GodwokenExplorer do
  @moduledoc """
  GodwokenExplorer keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def schema do
    quote do
      use Ecto.Schema

      import Ecto.{Query, Queryable, Changeset}

      alias Decimal, as: D
      alias Ecto.Multi
      alias GodwokenExplorer.{
        Account,
        AccountUDT,
        Block,
        CheckInfo,
        ContractMethod,
        DepositHistory,
        PendingTransaction,
        PolyjuiceCreator,
        Polyjuice,
        Repo,
        SmartContract,
        Transaction,
        TokenTransfer,
        UDT,
        UDTTransfer,
        Version,
        WithdrawalHistory,
        WithdrawalRequest
      }
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
