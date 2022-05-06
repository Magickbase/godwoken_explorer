defmodule GodwokenExplorer.Graphql.Middleware.TermRange do
  @behaviour Absinthe.Middleware

  # helper function
  def page_and_size_default_config() do
    [
      {:page,
       fn page ->
         if is_integer(page) and page >= 1 do
           true
         else
           {:error_msg, "page field out of limit(>0)"}
         end
       end},
      {:page_size,
       fn page_size ->
         if is_integer(page_size) and page_size >= 1 do
           true
         else
           {:error_msg, "page_size field out of limit(>0)"}
         end
       end}
    ]
  end

  def call(resolution, config) when is_list(config) do
    arguments = resolution.arguments
    input = arguments[:input]

    if is_nil(input) do
      resolution
    else
      case term_range(input, config) do
        true ->
          resolution

        {:error_msg, error_msg} ->
          resolution
          |> Absinthe.Resolution.put_result({:error, "#{inspect(error_msg)}"})
      end
    end
  end

  defp term_range(input, config) do
    Enum.reduce(config, true, fn {field, limit_fun}, acc ->
      if acc == true do
        case input[field] do
          nil ->
            acc

          input_field ->
            limit_fun.(input_field)
        end
      else
        {:error_msg, acc}
      end
    end)
  end
end
