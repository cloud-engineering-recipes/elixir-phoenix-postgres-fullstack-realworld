defmodule RealWorld.Articles do
  @moduledoc """
  The Articles context.
  """

  require Logger

  import Ecto.Query

  alias RealWorld.Articles.{Article, Comment, Favorite, Tag}
  alias RealWorld.Repo
  alias RealWorld.Users

  def create_article(attrs) when is_map_key(attrs, :author_id) do
    with {:ok, _} <- Users.get_user_by_id(attrs.author_id),
         {:ok, article} <-
           %Article{}
           |> Article.changeset(attrs)
           |> Repo.insert() do
      {:ok, Repo.preload(article, [:tags])}
    end
  end

  def get_article_by_id(article_id) do
    case Repo.get(Article, article_id) |> Repo.preload([:tags]) do
      nil -> {:not_found, "article #{article_id} not found"}
      article -> {:ok, article}
    end
  end

  def get_article_by_slug(slug) do
    case Repo.get_by(Article, slug: slug) |> Repo.preload([:tags]) do
      nil -> {:not_found, "slug #{slug} not found"}
      article -> {:ok, article}
    end
  end

  def list_articles(attrs \\ %{}) do
    query =
      Article
      |> join(:left, [a], assoc(a, :tags), as: :tags)
      |> join(:left, [a], assoc(a, :favorites), as: :favorites)
      |> where(^filter_articles_where(attrs))
      |> order_by(^filter_articles_order_by(attrs[:order_by]))

    query =
      if limit = attrs[:limit] || attrs["limit"] do
        query
        |> limit(^limit)
      else
        query
      end

    query =
      if offset = attrs[:offset] || attrs["offset"] do
        query
        |> offset(^offset)
      else
        query
      end

    with articles <-
           query
           |> Repo.all()
           |> Repo.preload([:tags]) do
      {:ok, articles}
    end
  end

  defp filter_articles_where(attrs) do
    Enum.reduce(attrs, dynamic(true), fn
      {:tag, value}, dynamic ->
        dynamic([tags: t], ^dynamic and t.name == ^value)

      {:author_id, value}, dynamic ->
        dynamic([a], ^dynamic and a.author_id == ^value)

      {:favorited_by, value}, dynamic ->
        dynamic([favorites: f], ^dynamic and f.user_id == ^value)

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end

  defp filter_articles_order_by(_) do
    [desc: :inserted_at]
  end

  def update_article(article_id, attrs) do
    with {:ok, article} <- get_article_by_id(article_id) do
      article
      |> Repo.preload([:tags])
      |> Article.changeset(attrs)
      |> Repo.update()
    end
  end

  def favorite_article(user_id, article_id) do
    with {:ok, is_favorited} <- is_favorited?(user_id, article_id) do
      if is_favorited do
        {:ok, nil}
      else
        with {:ok, _} <-
               %Favorite{}
               |> Favorite.changeset(%{user_id: user_id, article_id: article_id})
               |> Repo.insert() do
          {:ok, nil}
        end
      end
    end
  end

  def unfavorite_article(user_id, article_id) do
    with {:ok, is_favorited} <- is_favorited?(user_id, article_id) do
      if is_favorited do
        with {:ok, _} <-
               Repo.get_by!(Favorite, user_id: user_id, article_id: article_id)
               |> Repo.delete() do
          {:ok, nil}
        end
      else
        {:ok, nil}
      end
    end
  end

  def is_favorited?(user_id, article_id) do
    with {:ok, user} <- Users.get_user_by_id(user_id),
         {:ok, article} <- get_article_by_id(article_id) do
      case from(f in Favorite, where: f.user_id == ^user.id and f.article_id == ^article.id)
           |> Repo.one() do
        nil -> {:ok, false}
        _ -> {:ok, true}
      end
    end
  end

  def get_favorites_count(article_id) do
    with {:ok, article} <- get_article_by_id(article_id) do
      query = from(f in Favorite, where: f.article_id == ^article.id)

      {:ok, Repo.aggregate(query, :count)}
    end
  end

  def list_tags do
    with tags <-
           Tag
           |> order_by(asc: :name)
           |> Repo.all() do
      {:ok, tags}
    end
  end

  def add_comment(attrs) when is_map_key(attrs, :author_id) and is_map_key(attrs, :article_id) do
    with {:ok, _} <- Users.get_user_by_id(attrs.author_id),
         {:ok, _} <- get_article_by_id(attrs.article_id) do
      %Comment{}
      |> Comment.changeset(attrs)
      |> Repo.insert()
    end
  end

  def list_comments(attrs \\ %{}) do
    with comments <-
           Comment
           |> where(^filter_comments_where(attrs))
           |> order_by(^filter_comments_order_by(attrs[:order_by]))
           |> Repo.all() do
      {:ok, comments}
    end
  end

  defp filter_comments_where(attrs) do
    Enum.reduce(attrs, dynamic(true), fn
      {:article_id, value}, dynamic ->
        dynamic([c], ^dynamic and c.article_id == ^value)

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end

  defp filter_comments_order_by(_) do
    [desc: :inserted_at]
  end
end
