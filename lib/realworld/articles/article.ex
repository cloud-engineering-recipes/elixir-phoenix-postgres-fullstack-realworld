defmodule RealWorld.Articles.Article do
  @moduledoc """
  The Article model.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias RealWorld.Users.User

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "articles" do
    field :slug, :string
    field :title, :string
    field :description, :string
    field :body, :string
    field :tag_list, {:array, :string}

    belongs_to(:author, User, foreign_key: :author_id, type: :binary_id)

    timestamps()
  end

  def changeset(article, attrs) do
    article
    |> cast(attrs, [:author_id, :title, :description, :body, :tag_list])
    |> validate_required([:author_id, :title, :description, :body])
    |> assoc_constraint(:author)
    |> put_slug()
    |> put_tag_list()
    |> unique_constraint([:slug])
    |> unique_constraint([:author_id, :title])
  end

  defp put_slug(%Ecto.Changeset{valid?: true, changes: %{title: title}} = changeset) do
    change(changeset, slug: Slug.slugify(title))
  end

  defp put_slug(changeset), do: changeset

  defp put_tag_list(%Ecto.Changeset{valid?: true, changes: %{tag_list: tag_list}} = changeset) do
    change(changeset,
      tag_list:
        Enum.filter(tag_list, fn tag -> tag != nil end)
        |> Enum.map(fn tag ->
          tag |> String.trim() |> String.downcase() |> Slug.slugify()
        end)
        |> Enum.filter(fn tag -> tag != nil end)
    )
  end

  defp put_tag_list(changeset), do: changeset
end
