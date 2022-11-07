defmodule RealWorldWeb.TagView do
  use RealWorldWeb, :view
  alias RealWorldWeb.TagView

  def render("index.json", %{tags: tags}) do
    %{
      tags: render_many(tags, TagView, "tag.json")
    }
  end

  def render("tag.json", %{tag: tag}) do
    tag.name
  end
end
