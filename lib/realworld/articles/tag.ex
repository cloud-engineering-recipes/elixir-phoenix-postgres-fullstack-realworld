defmodule RealWorld.Articles.Tag do
  @moduledoc """
  The Tag model.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias RealWorld.Articles.Article

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "tags" do
    field :name, :string

    many_to_many :articles, Article, join_through: "articles_tags"

    timestamps()
  end

  def changeset(tag, attrs) do
    tag
    |> cast(attrs, [:name])
    |> validate_required([:name])
    |> unique_constraint([:name])
  end
end
