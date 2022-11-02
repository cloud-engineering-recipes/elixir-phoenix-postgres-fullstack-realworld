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
      add :tag_list, {:array, :string}

      timestamps(type: :utc_datetime)
    end

    create unique_index("articles", [:slug])
    execute("CREATE INDEX article_tag_list_index ON articles USING GIN(tag_list)")
  end
end
