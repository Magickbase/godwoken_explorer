defmodule GodwokenExplorer.Graphql.Common do
  import Ecto.Query

  def page_and_size(query, input, max_limit \\ 100) do
    page = Map.get(input, :page)
    page_size = Map.get(input, :page_size)

    case {page, page_size} do
      {nil, nil} ->
        query

      {nil, _} ->
        query

      {_, nil} ->
        query

      {page, page_size} when is_integer(page) and is_integer(page_size) ->
        page_size =
          if max_limit > page_size do
            page_size
          else
            max_limit
          end

        query
        |> offset((^page - 1) * ^page_size)
        |> limit(^page_size)

      _ ->
        query
    end
  end

  def sort_type(query, input, value) do
    sort_condtion = Map.get(input, :sort_type)

    case sort_condtion do
      :asc ->
        query
        |> order_by(asc: ^value)

      :desc ->
        query
        |> order_by(desc: ^value)
    end
  end
end
