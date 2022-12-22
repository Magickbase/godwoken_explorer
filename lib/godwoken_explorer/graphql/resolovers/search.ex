defmodule GodwokenExplorer.Graphql.Resolvers.Search do
  alias GodwokenExplorer.{UDT, Transaction, Block, Address, Account}
  alias GodwokenExplorer.Chain
  import Ecto.Query

  import GodwokenExplorer.Graphql.Resolvers.Common, only: [paginate_query: 3]

  def search_keyword(_parent, %{input: %{keyword: keyword}} = _args, _resolution) do
    do_search_keyword(keyword)
  end

  def do_search_keyword(keyword) do
    keyword
    |> String.trim()
    |> Chain.from_param()
    |> case do
      {:ok, item} ->
        return = process_result(item)
        {:ok, return}

      {:error, :not_found} ->
        {:error, :not_found}
    end
  end

  defp process_result(%Account{} = item) do
    id =
      case item.type do
        :eth_user -> item.eth_address
        :polyjuice_contract -> item.eth_address
        _ -> item.script_hash
      end

    %{type: :account, id: id}
  end

  defp process_result(%Address{} = item) do
    %{type: :address, id: item.eth_address}
  end

  defp process_result(%Block{} = item) do
    %{type: :block, id: item.number}
  end

  defp process_result(%Transaction{} = item) do
    %{type: :transaction, id: item.eth_hash || item.hash}
  end

  defp process_result(%UDT{} = item) do
    %{type: :udt, id: item.id}
  end

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
