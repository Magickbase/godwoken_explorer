defmodule GodwokenExplorerWeb.SentryFilter do
  @behaviour Sentry.EventFilter
  def exclude_exception?(%Phoenix.NotAcceptableError{}, :plug), do: true
  def exclude_exception?(_exception, _source), do: false
end
