defmodule RealWorld.Articles.Favorite do
  @moduledoc """
  The Favorite model.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias RealWorld.Articles.Article
  alias RealWorld.Users.User

  @primary_key false
  schema "favorites" do
    belongs_to(:user, User, primary_key: true, type: :binary_id)
    belongs_to(:article, Article, primary_key: true, type: :binary_id)

    timestamps(updated_at: false)
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:user_id, :article_id])
    |> validate_required([:user_id, :article_id])
    |> unique_constraint([:user_id, :article_id])
  end
end
