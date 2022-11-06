defmodule RealWorld.Articles do
  @moduledoc """
  The Articles context.
  """

  require Logger

  import Ecto.Query

  alias RealWorld.Articles.{Article, Favorite}
  alias RealWorld.Repo
  alias RealWorld.Users

  def create_article(
        %{
          author_id: author_id,
          title: _title,
          description: _description,
          body: _body,
          tag_list: _tag_list
        } = attrs
      ) do
    with {:ok, _} <- Users.get_user_by_id(author_id) do
      %Article{}
      |> Article.changeset(attrs)
      |> Repo.insert()
    end
  end

  def get_article_by_id(article_id) do
    case Repo.get(Article, article_id) do
      nil -> {:not_found, "Article #{article_id} not found"}
      article -> {:ok, article}
    end
  end

  def get_article_by_slug(slug) do
    case Repo.get_by(Article, slug: slug) do
      nil -> {:not_found, "Slug #{slug} not found"}
      article -> {:ok, article}
    end
  end

  def list_articles(params \\ %{}) do
    with articles <-
           Article
           |> where(^filter_articles_where(params))
           |> order_by(^filter_articles_order_by(params[:order_by]))
           |> Repo.all() do
      {:ok, articles}
    end
  end

  defp filter_articles_where(params) do
    Enum.reduce(params, dynamic(true), fn
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
    with {:ok, article} <- get_article_by_id(article_id) do
      article
      |> Article.changeset(attrs)
      |> Repo.update()
    end
  end

  def favorite_article(%{user_id: user_id, article_id: article_id}) do
    with {:ok, is_favorited} <- is_favorited?(%{user_id: user_id, article_id: article_id}) do
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

  def is_favorited?(%{user_id: user_id, article_id: article_id}) do
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
