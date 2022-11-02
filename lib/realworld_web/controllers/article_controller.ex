defmodule RealWorldWeb.ArticleController do
  use RealWorldWeb, :controller

  require Logger

  alias RealWorld.{Articles, Profiles, Users}
  alias RealWorldWeb.Dtos.{ArticleDto, ProfileDto}

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
      article_dto = %ArticleDto{
        slug: article.slug,
        title: article.title,
        description: article.description,
        body: article.body,
        tagList: article.tag_list,
        createdAt: article.inserted_at,
        updatedAt: article.updated_at,
        favorited: false,
        favoritesCount: 0,
        author: %ProfileDto{
          username: author.username,
          bio: author.bio,
          image: author.image,
          following: false
        }
      }

      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.article_path(conn, :get_article, article.slug))
      |> render("show.json", %{article: article_dto})
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

      is_author_followed =
        if user_id != nil do
          {:ok, is_author_followed} =
            Profiles.is_following?(%{follower_id: user_id, followed_id: article.author_id})

          is_author_followed
        else
          false
        end

      article_dto = %ArticleDto{
        slug: article.slug,
        title: article.title,
        description: article.description,
        body: article.body,
        tagList: article.tag_list,
        createdAt: article.inserted_at,
        updatedAt: article.updated_at,
        favorited: is_favorited,
        favoritesCount: favorites_count,
        author: %ProfileDto{
          username: author.username,
          bio: author.bio,
          image: author.image,
          following: is_author_followed
        }
      }

      conn
      |> render("show.json", %{
        article: article_dto
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
      {:ok, is_author_followed} =
        Profiles.is_following?(%{follower_id: user.id, followed_id: article.author_id})

      {:ok, favorites_count} = Articles.get_favorites_count(article.id)

      article_dto = %ArticleDto{
        slug: article.slug,
        title: article.title,
        description: article.description,
        body: article.body,
        tagList: article.tag_list,
        createdAt: article.inserted_at,
        updatedAt: article.updated_at,
        favorited: true,
        favoritesCount: favorites_count,
        author: %ProfileDto{
          username: author.username,
          bio: author.bio,
          image: author.image,
          following: is_author_followed
        }
      }

      conn
      |> render("show.json", %{article: article_dto})
    end
  end
end
