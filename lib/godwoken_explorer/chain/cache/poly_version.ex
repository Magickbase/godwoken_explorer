defmodule GodwokenExplorer.Chain.Cache.PolyVersion do
  @moduledoc """
  Cache for block count.
  """

  @default_cache_period :timer.hours(24)

  use GodwokenExplorer.Chain.MapCache,
    name: :poly_version,
    key: :version,
    key: :async_task,
    global_ttl: cache_period(),
    ttl_check_interval: :timer.hours(1),
    callback: &async_task_on_deletion(&1)

  require Logger

  alias GodwokenRPC

  defp handle_fallback(:version) do
    # This will get the task PID if one exists and launch a new task if not
    # See next `handle_fallback` definition
    get_async_task()

    {:return, nil}
  end

  defp handle_fallback(:async_task) do
    # If this gets called it means an async task was requested, but none exists
    # so a new one needs to be launched
    {:ok, task} =
      Task.start(fn ->
        try do
          {:ok, result} = GodwokenRPC.fetch_poly_version()

          set_version(result["versions"])
        rescue
          e ->
            Logger.debug([
              "Coudn't update poly version #{inspect(e)}"
            ])
        end

        set_async_task(nil)
      end)

    {:update, task}
  end

  # By setting this as a `callback` an async task will be started each time the
  # `count` expires (unless there is one already running)
  defp async_task_on_deletion({:delete, _, :count}), do: get_async_task()

  defp async_task_on_deletion(_data), do: nil

  defp cache_period do
    @default_cache_period
  end
end
