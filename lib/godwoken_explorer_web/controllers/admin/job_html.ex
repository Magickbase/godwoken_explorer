defmodule GodwokenExplorerWeb.Admin.JobHTML do
  use GodwokenExplorerWeb, :html

  use Phoenix.HTML
  use Phoenix.View, root: "job_html/"

  import Torch.TableView
  import Torch.FilterView

  embed_templates("job_html/*")
end
