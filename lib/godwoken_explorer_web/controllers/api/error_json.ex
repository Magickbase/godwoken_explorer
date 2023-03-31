defmodule GodwokenExplorerWeb.API.ErrorJSON do
  # If you want to customize a particular status code,
  # you may add your own clauses, such as:
  #
  # def render("500.json", _assigns) do
  #   %{errors: %{detail: "Internal Server Error"}}
  # end

  # By default, Phoenix returns the status message from
  # the template name. For example, "404.json" becomes
  # "Not Found".

  def render("10001.json", %{eth_hash: eth_hash}) do
    # When encoded, the changeset returns its errors
    # as a JSON object. So we just pass it forward.
    %{
      errors: %{
        status: "400",
        title: "Please use eth hash query, not godwoken hash",
        detail: "The eth hash is #{eth_hash}."
      }
    }
  end

  def render("404.json", _assigns) do
    # When encoded, the changeset returns its errors
    # as a JSON object. So we just pass it forward.
    %{
      errors: %{
        status: "404",
        title: "not found",
        detail: ""
      }
    }
  end

  def render("400.json", _assigns) do
    # When encoded, the changeset returns its errors
    # as a JSON object. So we just pass it forward.
    %{
      errors: %{
        status: "400",
        title: "bad request",
        detail: ""
      }
    }
  end

  def render(template, _assigns) do
    %{errors: %{detail: Phoenix.Controller.status_message_from_template(template)}}
  end
end
