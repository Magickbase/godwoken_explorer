defmodule GodwokenExplorerWeb.ErrorViewTest do
  use GodwokenExplorerWeb.ConnCase, async: true

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  test "renders 404.json" do
    assert render(GodwokenExplorerWeb.ErrorView, "404.json", %{title: "account not found", detail: ""}) ==
      %{
        errors:  %{
          status: "404",
          title: "not found",
          detail: ""
        }
      }
  end
end
