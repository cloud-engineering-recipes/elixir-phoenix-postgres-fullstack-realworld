defmodule RealWorldWeb.TagController do
  use RealWorldWeb, :controller

  require Logger

  alias RealWorld.Articles

  action_fallback(RealWorldWeb.FallbackController)

  def get_tags(conn, _params) do
    with {:ok, tags} <- Articles.list_tags() do
      render(conn, "index.json", %{tags: tags})
    end
  end
end
