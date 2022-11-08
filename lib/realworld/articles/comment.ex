defmodule RealWorld.Articles.Comment do
  @moduledoc """
  The Comment model.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias RealWorld.Articles.Article
  alias RealWorld.Users.User

  @primary_key {:id, :binary_id, autogenerate: true}
  @timestamps_opts [type: :utc_datetime]
  schema "comments" do
    field :body, :string

    belongs_to(:author, User, type: :binary_id)
    belongs_to(:article, Article, type: :binary_id)

    timestamps()
  end

  def changeset(comment, attrs) do
    comment
    |> cast(attrs, [:author_id, :article_id, :body])
    |> validate_required([:author_id, :article_id, :body])
  end
end
