defmodule RealWorld.Articles.Article do
  @moduledoc """
  The Article model.
  """

  use Ecto.Schema
  import Ecto.Changeset
  alias RealWorld.Articles.Tag
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

    timestamps()
  end

  def changeset(article, attrs) do
    article
    |> cast(attrs, [:author_id, :title, :description, :body])
    |> validate_required([:author_id, :title, :description, :body])
    |> put_slug()
    |> put_assoc(:tags, get_or_insert_tags(attrs))
    |> unique_constraint([:slug])
    |> unique_constraint([:author_id, :title])
  end

  defp put_slug(%Ecto.Changeset{valid?: true, changes: %{title: title}} = changeset) do
    change(changeset, slug: Slug.slugify(title))
  end

  defp put_slug(changeset), do: changeset

  defp get_or_insert_tags(attrs) when is_map_key(attrs, :tags) do
    get_or_insert_tags(attrs[:tags])
  end

  defp get_or_insert_tags(attrs) when is_map_key(attrs, "tags") do
    get_or_insert_tags(attrs["tags"])
  end

  defp get_or_insert_tags(tag_names) when is_list(tag_names) do
    tag_names
    |> Enum.map(fn name -> format_tag_name(name) end)
    |> Enum.reject(fn name -> name == nil end)
    |> Enum.map(fn name -> get_or_insert_tag(name) end)
  end

  defp get_or_insert_tags(_) do
    []
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
