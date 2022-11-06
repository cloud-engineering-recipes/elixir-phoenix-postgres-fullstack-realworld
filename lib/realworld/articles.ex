defmodule RealWorld.Articles do
  @moduledoc """
  The Articles context.
  """

  require Logger

  import Ecto.Query

  alias RealWorld.Articles.{Article, Favorite}
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
      nil -> {:not_found, "Article #{article_id} not found"}
      article -> {:ok, article}
    end
  end

  def get_article_by_slug(slug) do
    case Repo.get_by(Article, slug: slug) |> Repo.preload([:tags]) do
      nil -> {:not_found, "Slug #{slug} not found"}
      article -> {:ok, article}
    end
  end

  def list_articles(attrs \\ %{}) do
    with articles <-
           Article
           |> join(:left, [a], assoc(a, :tags), as: :tags)
           |> where(^filter_articles_where(attrs))
           |> order_by(^filter_articles_order_by(attrs[:order_by]))
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

      {_, _}, dynamic ->
        # Not a where parameter
        dynamic
    end)
  end

  defp filter_articles_order_by(_),
    do: [desc: dynamic([a], a.inserted_at)]

  def update_article(article_id, attrs) do
    with {:ok, article} <- get_article_by_id(article_id),
         {:ok, updated_article} <-
           article
           |> Article.changeset(attrs)
           |> Repo.update() do
      {:ok,
       updated_article
       |> Repo.preload([:tags])}
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

  def is_favorited?(user_id, article_id) do
    with {:ok, user} <- Users.get_user_by_id(user_id),
         {:ok, article} <- get_article_by_id(article_id) do
      case Repo.get_by(Favorite, user_id: user.id, article_id: article.id) do
        nil -> {:ok, false}
        _ -> {:ok, true}
      end
    end
  end

  def get_favorites_count(article_id) do
    with {:ok, article} <- get_article_by_id(article_id) do
      query = from(f in Favorite, select: f.id, where: f.article_id == ^article.id)

      {:ok, Repo.aggregate(query, :count, :id)}
    end
  end
end
