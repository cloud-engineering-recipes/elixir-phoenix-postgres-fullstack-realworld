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
          "tagList" => tags
        }
      }) do
    author = conn.private.guardian_default_resource

    with {:ok, article} <-
           %{
             author_id: author.id,
             title: title,
             description: description,
             body: body,
             tags: tags
           }
           |> Articles.create_article(),
         {:ok, author} <- Users.get_user_by_id(author.id) do
      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.article_path(conn, :get_article, article.slug))
      |> render("show.json", %{
        article:
          article
          |> Map.put(:is_favorited, false)
          |> Map.put(:favorites_count, 0)
          |> Map.put(:author, author)
          |> Map.put(:is_following_author, false)
      })
    end
  end

  def create_article(conn, %{
        "article" =>
          %{
            "title" => _title,
            "description" => _description,
            "body" => _body
          } = create_article_params
      }) do
    create_article(conn, Map.put(create_article_params, "tagList", []))
  end

  def get_article(conn, %{"slug" => slug}) do
    with {:ok, article} <- Articles.get_article_by_slug(slug),
         {:ok, author} <- Users.get_user_by_id(article.author_id),
         {:ok, favorites_count} <- Articles.get_favorites_count(article.id) do
      user_id =
        if user = conn.private[:guardian_default_resource] do
          user.id
        else
          nil
        end

      is_favorited =
        if user_id != nil do
          {:ok, is_favorited} = Articles.is_favorited?(user_id, article.id)

          is_favorited
        else
          false
        end

      is_following_author =
        if user_id != nil do
          {:ok, is_following_author} = Profiles.is_following?(user_id, article.author_id)

          is_following_author
        else
          false
        end

      render(conn, "show.json", %{
        article:
          article
          |> Map.put(:is_favorited, is_favorited)
          |> Map.put(:favorites_count, favorites_count)
          |> Map.put(:author, author)
          |> Map.put(:is_following_author, is_following_author)
      })
    end
  end

  def list_articles(conn, params) do
    list_articles_filters = %{}

    list_articles_filters =
      if tag = params["tag"] do
        Map.put(list_articles_filters, :tag, tag)
      else
        list_articles_filters
      end

    list_articles_filters =
      if author_username = params["author"] do
        with {:ok, author} <- Users.get_user_by_username(author_username) do
          Map.put(list_articles_filters, :author_id, author.id)
        end
      else
        list_articles_filters
      end

    list_articles_filters =
      if favorited_by_username = params["favorited"] do
        with {:ok, favorited_by} <- Users.get_user_by_username(favorited_by_username) do
          Map.put(list_articles_filters, :favorited_by, favorited_by.id)
        end
      else
        list_articles_filters
      end

    list_articles_filters =
      if limit = params["limit"] do
        Map.put(list_articles_filters, :limit, limit)
      else
        Map.put(list_articles_filters, :limit, 20)
      end

    list_articles_filters =
      if offset = params["offset"] do
        Map.put(list_articles_filters, :offset, offset)
      else
        Map.put(list_articles_filters, :offset, 0)
      end

    with {:ok, articles} <- Articles.list_articles(list_articles_filters) do
      articles =
        articles
        |> Enum.map(fn article ->
          with {:ok, author} <- Users.get_user_by_id(article.author_id) do
            Map.put(article, :author, author)
          end
        end)
        |> Enum.map(fn article ->
          with {:ok, favorites_count} <- Articles.get_favorites_count(article.id) do
            Map.put(article, :favorites_count, favorites_count)
          end
        end)

      user_id =
        if user = conn.private[:guardian_default_resource] do
          user.id
        else
          nil
        end

      articles =
        if user_id do
          articles
          |> Enum.map(fn article ->
            with {:ok, is_favorited} <- Articles.is_favorited?(user_id, article.id),
                 {:ok, is_following_author} <- Profiles.is_following?(user_id, article.author_id) do
              article
              |> Map.put(:is_favorited, is_favorited)
              |> Map.put(:is_following_author, is_following_author)
            end
          end)
        else
          articles
          |> Enum.map(&Map.put(&1, :is_favorited, false))
          |> Enum.map(&Map.put(&1, :is_following_author, false))
        end

      render(conn, "index.json", articles: articles)
    end
  end

  def update_article(conn, %{
        "slug" => slug,
        "article" => update_article_params
      }) do
    author = conn.private.guardian_default_resource

    with {:ok, article} <- Articles.get_article_by_slug(slug) do
      if author.id == article.author_id do
        with {:ok, updated_article} <-
               Articles.update_article(
                 article.id,
                 update_article_params |> Map.put("tags", update_article_params["tagList"] || [])
               ),
             {:ok, favorites_count} <- Articles.get_favorites_count(article.id) do
          render(conn, "show.json", %{
            article:
              updated_article
              |> Map.put(:is_favorited, false)
              |> Map.put(:favorites_count, favorites_count)
              |> Map.put(:author, author)
              |> Map.put(:is_following_author, false)
          })
        end
      else
        Logger.error(
          "User #{author.id} tried to update article #{article.id} from author #{article.author_id}."
        )

        {:unauthorized, "Unauthorized"}
      end
    end
  end

  def favorite_article(conn, %{
        "slug" => slug
      }) do
    user = conn.private.guardian_default_resource

    with {:ok, article} <- Articles.get_article_by_slug(slug),
         {:ok, _} <- Articles.favorite_article(user.id, article.id),
         {:ok, author} <- Users.get_user_by_id(article.author_id) do
      {:ok, is_following_author} = Profiles.is_following?(user.id, article.author_id)

      {:ok, favorites_count} = Articles.get_favorites_count(article.id)

      render(conn, "show.json", %{
        article:
          article
          |> Map.put(:is_favorited, true)
          |> Map.put(:favorites_count, favorites_count)
          |> Map.put(:author, author)
          |> Map.put(:is_following_author, is_following_author)
      })
    end
  end

  def unfavorite_article(conn, %{
        "slug" => slug
      }) do
    user = conn.private.guardian_default_resource

    with {:ok, article} <- Articles.get_article_by_slug(slug),
         {:ok, _} <- Articles.unfavorite_article(user.id, article.id),
         {:ok, author} <- Users.get_user_by_id(article.author_id) do
      {:ok, is_following_author} = Profiles.is_following?(user.id, article.author_id)

      {:ok, favorites_count} = Articles.get_favorites_count(article.id)

      render(conn, "show.json", %{
        article:
          article
          |> Map.put(:is_favorited, true)
          |> Map.put(:favorites_count, favorites_count)
          |> Map.put(:author, author)
          |> Map.put(:is_following_author, is_following_author)
      })
    end
  end
end
