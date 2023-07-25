defmodule GodwokenExplorerWeb.Admin.JobHTML do
  use GodwokenExplorerWeb, :html

  use Phoenix.HTML

  import Torch.TableView
  import Torch.FilterView
  import Torch.Component

  embed_templates("job_html/*")
end
