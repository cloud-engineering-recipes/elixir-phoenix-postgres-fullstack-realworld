defmodule RealWorldWeb.CommentView do
  use RealWorldWeb, :view
  alias RealWorldWeb.CommentView

  def render("index.json", %{comments: comments}) do
    %{
      comments: render_many(comments, CommentView, "comment.json")
    }
  end

  def render("show.json", %{comment: comment}) do
    %{comment: render_one(comment, CommentView, "comment.json")}
  end

  def render("comment.json", %{comment: comment}) do
    %{
      id: comment.id,
      createdAt: DateTime.to_iso8601(comment.inserted_at),
      updatedAt: DateTime.to_iso8601(comment.updated_at),
      body: comment.body,
      author: %{
        username: comment.author.username,
        bio: comment.author.bio,
        image: comment.author.image,
        following: comment.is_following_author
      }
    }
  end
end
