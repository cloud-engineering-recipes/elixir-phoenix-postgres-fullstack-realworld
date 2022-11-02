defmodule RealWorldWeb.ArticleView do
  use RealWorldWeb, :view
  alias RealWorldWeb.ArticleView

  def render("show.json", %{
        article: article
      }) do
    %{
      article: render_one(article, ArticleView, "article.json")
    }
  end

  def render("article.json", %{article: article}) do
    article
  end
end
