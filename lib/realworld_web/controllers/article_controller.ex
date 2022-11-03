defmodule RealWorldWeb.ArticleController do
  use RealWorldWeb, :controller

  require Logger

  alias RealWorld.{Articles, Profiles, Users}

  action_fallback(RealWorldWeb.FallbackController)

  def create_article(conn, %{
        "article" => %{
          "title" => title,
          "description" => description,
          "body" => body,
          "tag_list" => tag_list
        }
      }) do
    author = conn.private.guardian_default_resource

    with {:ok, article} <-
           %{
             author_id: author.id,
             title: title,
             description: description,
             body: body,
             tag_list: tag_list
           }
           |> Articles.create_article(),
         {:ok, author} <- Users.get_user_by_id(author.id) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.article_path(conn, :get_article, article.slug))
      |> render("show.json", %{
        article: article,
        is_favorited: false,
        favorites_count: 0,
        author: author,
        is_following_author: false
      })
    end
  end

  def get_article(conn, %{"slug" => slug}) do
    user_id =
      if Map.has_key?(conn.private, :guardian_default_resource) do
        conn.private.guardian_default_resource.id
      else
        nil
      end

    with {:ok, article} <- Articles.get_article_by_slug(slug),
         {:ok, author} <- Users.get_user_by_id(article.author_id),
         {:ok, favorites_count} <- Articles.get_favorites_count(article.id) do
      is_favorited =
        if user_id != nil do
          {:ok, is_favorited} =
            Articles.is_favorited?(%{user_id: user_id, article_id: article.id})

          is_favorited
        else
          false
        end

      is_following_author =
        if user_id != nil do
          {:ok, is_following_author} =
            Profiles.is_following?(%{follower_id: user_id, followed_id: article.author_id})

          is_following_author
        else
          false
        end

      render(conn, "show.json", %{
        article: article,
        is_favorited: is_favorited,
        favorites_count: favorites_count,
        author: author,
        is_following_author: is_following_author
      })
    end
  end

  def favorite_article(conn, %{
        "slug" => slug
      }) do
    user = conn.private.guardian_default_resource

    with {:ok, article} <- Articles.get_article_by_slug(slug),
         {:ok, _} <- Articles.favorite_article(%{user_id: user.id, article_id: article.id}),
         {:ok, author} <- Users.get_user_by_id(article.author_id) do
      {:ok, is_following_author} =
        Profiles.is_following?(%{follower_id: user.id, followed_id: article.author_id})

      {:ok, favorites_count} = Articles.get_favorites_count(article.id)

      render(conn, "show.json", %{
        article: article,
        is_favorited: true,
        favorites_count: favorites_count,
        author: author,
        is_following_author: is_following_author
      })
    end
  end
end
