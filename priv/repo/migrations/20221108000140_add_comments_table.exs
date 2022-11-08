defmodule RealWorld.Repo.Migrations.AddCommentsTable do
  use Ecto.Migration

  def change do
    create table("comments", primary_key: false) do
      add :id, :uuid, primary_key: true
      add :author_id, references("users", type: :uuid)
      add :article_id, references("articles", type: :uuid)
      add :body, :text, null: false

      timestamps(type: :utc_datetime)
    end
  end
end
