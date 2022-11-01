defmodule RealWorld.Articles do
  @moduledoc """
  The Articles context.
  """

  require Logger

  alias RealWorld.Articles.Article
  alias RealWorld.Repo
  alias RealWorld.Users

  def create_article(
        %{
          author_id: author_id,
          title: title,
          description: _description,
          body: _body,
          tag_list: _tag_list
        } = attrs
      ) do
    Logger.info("create_article. author_id: #{author_id}; title: #{title}...")

    with {:ok, author} <- Users.get_user_by_id(author_id),
         {:ok, article} <-
           %Article{}
           |> Article.changeset(attrs)
           |> Repo.insert() do
      Logger.info("create_article successful! author_id: #{author.id}; title: #{title}")
      {:ok, article}
    end
  end

  def get_article_by_id(article_id) do
    Logger.debug("get_article_by_id #{article_id}...")

    case Repo.get(Article, article_id) do
      nil -> {:not_found, "Article #{article_id} not found"}
      article -> {:ok, article}
    end
  end
end
