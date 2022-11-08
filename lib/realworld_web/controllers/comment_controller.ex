defmodule RealWorldWeb.CommentController do
  use RealWorldWeb, :controller

  require Logger

  alias RealWorld.{Articles, Profiles, Users}

  action_fallback(RealWorldWeb.FallbackController)

  def add_comment(conn, %{"slug" => slug, "comment" => %{"body" => body}}) do
    author = conn.private.guardian_default_resource

    with {:ok, article} <- Articles.get_article_by_slug(slug),
         {:ok, comment} <-
           Articles.add_comment(%{author_id: author.id, article_id: article.id, body: body}) do
      conn
      |> put_status(:created)
      |> render("show.json", %{
        comment:
          comment
          |> Map.put(:author, author)
          |> Map.put(:is_following_author, false)
      })
    end
  end

  def get_article_comments(conn, %{"slug" => slug}) do
    with {:ok, article} <- Articles.get_article_by_slug(slug),
         {:ok, comments} <- Articles.list_comments(%{article_id: article.id}) do
      comments =
        comments
        |> Enum.map(fn comment ->
          with {:ok, author} <- Users.get_user_by_id(comment.author_id) do
            Map.put(comment, :author, author)
          end
        end)

      comments =
        if user = conn.private[:guardian_default_resource] do
          comments
          |> Enum.map(fn comment ->
            with {:ok, is_following_author} <- Profiles.is_following?(user.id, comment.author_id) do
              Map.put(comment, :is_following_author, is_following_author)
            end
          end)
        else
          comments
          |> Enum.map(&Map.put(&1, :is_following_author, false))
        end

      render(conn, "index.json", %{comments: comments})
    end
  end

  def delete_comment(conn, %{"slug" => _, "id" => comment_id}) do
    author = conn.private.guardian_default_resource

    with {:ok, comment} <- Articles.get_comment_by_id(comment_id) do
      if comment.author_id == author.id do
        with {:ok, _} <- Articles.delete_comment(comment_id) do
          conn
          |> put_status(:no_content)
          |> json(%{})
        end
      else
        Logger.error(
          "User #{author.id} tried to update comment #{comment.id} from author #{comment.author_id}."
        )

        {:unauthorized, "Unauthorized"}
      end
    end
  end
end
