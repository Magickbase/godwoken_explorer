defmodule GodwokenExplorer.Chain.Cache do
  def children() do
    [
      {ConCache,
       [
         name: :cache_sc,
         ttl_check_interval: :timer.minutes(15),
         global_ttl: :timer.hours(1)
       ]}
    ]
  end
end
