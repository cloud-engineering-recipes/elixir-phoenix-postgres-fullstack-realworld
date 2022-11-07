defmodule RealWorldWeb.ArticleView do
  use RealWorldWeb, :view
  alias RealWorldWeb.ArticleView

  def render("index.json", %{articles: articles}) do
    %{
      articles: render_many(articles, ArticleView, "article.json"),
      articlesCount: length(articles)
    }
  end

  def render("show.json", %{article: article}) do
    %{
      article: render_one(article, ArticleView, "article.json")
    }
  end

  def render("article.json", %{article: article}) do
    %{
      slug: article.slug,
      title: article.title,
      description: article.description,
      body: article.body,
      tagList: article.tags |> Enum.map(& &1.name),
      createdAt: Date.to_iso8601(article.inserted_at),
      updatedAt: Date.to_iso8601(article.updated_at),
      favorited: article.is_favorited,
      favoritesCount: article.favorites_count,
      author: %{
        username: article.author.username,
        bio: article.author.bio,
        image: article.author.image,
        following: article.is_following_author
      }
    }
  end
end
