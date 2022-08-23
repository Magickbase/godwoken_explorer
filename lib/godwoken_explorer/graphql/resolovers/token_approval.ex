defmodule GodwokenExplorer.Graphql.Resolvers.TokenApproval do
  import Ecto.Query
  import GodwokenExplorer.Graphql.Common, only: [cursor_order_sorter: 3]

  import GodwokenExplorer.Graphql.Resolvers.Common,
    only: [paginate_query: 3]

  alias GodwokenExplorer.{Block, TokenApproval, UDT}
  alias GodwokenExplorer.Repo

  @sorter_fields [:block_number, :id]

  def token_approvals(_parent, %{input: input}, _resolution) do
    query =
      from(ta in TokenApproval,
        join: u in UDT,
        on: u.contract_address_hash == ta.token_contract_address_hash,
        where:
          ta.approved == true and ta.token_owner_address_hash == ^input[:address] and
            u.eth_type == ^input[:token_type]
      )

    return =
      query
      |> token_approvals_order_by(input)
      |> paginate_query(input, %{
        cursor_fields: paginate_cursor(input),
        total_count_primary_key_field: :id
      })

    {:ok, return}
  end

  def block(%TokenApproval{block_hash: block_hash}, _args, _resolution) do
    {:ok, Repo.get(Block, block_hash)}
  end

  def udt(
        %TokenApproval{token_contract_address_hash: token_contract_address_hash},
        _args,
        _resolution
      ) do
    udt = UDT.get_by_contract_address(token_contract_address_hash)
    {:ok, udt}
  end

  defp token_approvals_order_by(query, input) do
    sorter = Map.get(input, :sorter)

    if sorter do
      order_params = cursor_order_sorter(sorter, :order, @sorter_fields)
      order_by(query, [u], ^order_params)
    else
      order_by(query, [u], [:block_number, :id])
    end
  end

  defp paginate_cursor(input) do
    sorter = Map.get(input, :sorter)

    if sorter do
      cursor_order_sorter(sorter, :cursor, @sorter_fields)
    else
      [:block_number, :id]
    end
  end
end
