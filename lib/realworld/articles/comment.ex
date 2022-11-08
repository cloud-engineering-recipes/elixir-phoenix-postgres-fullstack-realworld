defmodule RealWorld.Articles.Comment do
  @moduledoc """
  The Comment model.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias RealWorld.Articles.Article
  alias RealWorld.Users.User

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "comments" do
    field :body, :string

    belongs_to(:user, User, type: :binary_id)
    belongs_to(:article, Article, type: :binary_id)

    timestamps(updated_at: false)
  end

  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:user_id, :article_id, :body])
    |> validate_required([:user_id, :article_id, :body])
  end
end
