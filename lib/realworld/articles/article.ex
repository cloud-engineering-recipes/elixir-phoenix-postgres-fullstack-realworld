defmodule RealWorld.Articles.Article do
  @moduledoc """
  The Article model.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias RealWorld.Articles.{Favorite, Tag}
  alias RealWorld.Repo

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "articles" do
    field :author_id, :binary_id
    field :slug, :string
    field :title, :string
    field :description, :string
    field :body, :string

    many_to_many :tags, Tag,
      join_through: "articles_tags",
      on_replace: :delete

    has_many(:favorites, Favorite)

    timestamps()
  end

  def changeset(article, attrs) do
    article
    |> cast(attrs, [:author_id, :title, :description, :body])
    |> validate_required([:author_id, :title, :description, :body])
    |> put_slug()
    |> maybe_put_tags(attrs)
    |> unique_constraint([:slug])
    |> unique_constraint([:author_id, :title])
  end

  defp put_slug(%Ecto.Changeset{valid?: true, changes: %{title: title}} = changeset) do
    change(changeset, slug: Slug.slugify(title))
  end

  defp put_slug(changeset), do: changeset

  defp maybe_put_tags(changeset, attrs) do
    if tag_names = attrs[:tags] || attrs["tags"] do
      put_assoc(changeset, :tags, get_or_insert_tags(tag_names))
    else
      changeset
    end
  end

  defp get_or_insert_tags(tag_names) when is_list(tag_names) do
    tag_names
    |> Enum.map(&format_tag_name(&1))
    |> Enum.filter(&(&1 != nil))
    |> Enum.dedup()
    |> Enum.map(&get_or_insert_tag(&1))
  end

  defp format_tag_name(tag_name) when tag_name == nil do
    nil
  end

  defp format_tag_name(tag_name) do
    tag_name
    |> String.trim()
    |> String.downcase()
    |> Slug.slugify()
  end

  defp get_or_insert_tag(name) do
    Repo.get_by(Tag, name: name) || Repo.insert!(%Tag{name: name})
  end
end
