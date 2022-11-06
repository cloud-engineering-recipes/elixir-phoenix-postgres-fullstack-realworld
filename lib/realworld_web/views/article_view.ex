defmodule RealWorldWeb.ArticleView do
  use RealWorldWeb, :view
  alias RealWorldWeb.ArticleView

  def render("show.json", %{
        article: article,
        is_favorited: is_favorited,
        favorites_count: favorites_count,
        author: author,
        is_following_author: is_following_author
      }) do
    %{
      article:
        render_one(article, ArticleView, "article.json",
          is_favorited: is_favorited,
          favorites_count: favorites_count,
          author: author,
          is_following_author: is_following_author
        )
    }
  end

  def render("article.json", %{
        article: article,
        is_favorited: is_favorited,
        favorites_count: favorites_count,
        author: author,
        is_following_author: is_following_author
      }) do
    %{
      slug: article.slug,
      title: article.title,
      description: article.description,
      body: article.body,
      tagList: article.tags |> Enum.map(fn tag -> tag.name end),
      createdAt: Date.to_iso8601(article.inserted_at),
      updatedAt: Date.to_iso8601(article.updated_at),
      favorited: is_favorited,
      favoritesCount: favorites_count,
      author: %{
        username: author.username,
        bio: author.bio,
        image: author.image,
        following: is_following_author
      }
    }
  end
end
