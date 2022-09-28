defmodule GodwokenExplorer.Graphql.Utils do
  def default_uniq_cursor_order_fields(cursor_order_params, type, uniq_fields)
      when type in [:cursor, :order] do
    base =
      Enum.map(cursor_order_params, fn {e1, e2} ->
        if type == :cursor do
          e1
        else
          e2
        end
      end)

    extend = uniq_fields -- base

    extend =
      if type == :cursor do
        extend |> Enum.map(fn e -> {e, :asc} end)
      else
        extend |> Enum.map(fn e -> {:asc, e} end)
      end

    cursor_order_params ++ extend
  end
end
