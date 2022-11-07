defmodule RealWorld.Repo.Migrations.AddArticlesTable do
  use Ecto.Migration

  def change do
    create table("articles", primary_key: false) do
      add :id, :uuid, primary_key: true
      add :author_id, references("users", type: :uuid), null: false
      add :slug, :string, null: false
      add :title, :string, null: false
      add :description, :text, null: false
      add :body, :text, null: false
      add :tags, {:array, :string}

      timestamps(type: :utc_datetime)
    end

    create unique_index("articles", [:slug])

    create table("tags", primary_key: false) do
      add :id, :uuid, primary_key: true
      add :name, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index("tags", [:name])

    create table("articles_tags", primary_key: false) do
      add :article_id, references("articles", type: :uuid)
      add :tag_id, references("tags", type: :uuid)
    end
  end
end
