defmodule GodwokenExplorer.Graphql.Resolvers.Search do
  alias GodwokenExplorer.UDT
  import Ecto.Query

  import GodwokenExplorer.Graphql.Resolvers.Common, only: [paginate_query: 3]

  def search_udt(_parent, %{input: input} = _args, _resolution) do
    return =
      from(u in UDT)
      |> search_udt_condition(input)
      |> serach_udt_order(input)
      |> paginate_query(input, %{
        cursor_fields: [id: :desc],
        total_count_primary_key_field: :id
      })

    {:ok, return}
  end

  defp search_udt_condition(query, input) do
    fuzzy_name = Map.get(input, :fuzzy_name)
    contract_address = Map.get(input, :contract_address)

    query =
      if fuzzy_name do
        query
        |> where([u], ilike(u.name, ^fuzzy_name) or ilike(u.display_name, ^fuzzy_name))
      else
        query
      end

    if(contract_address) do
      query
      |> where([u], u.contract_address_hash == ^contract_address)
    else
      query
    end
  end

  defp serach_udt_order(query, _input) do
    query
    |> order_by([u], desc: u.id)
  end
end
