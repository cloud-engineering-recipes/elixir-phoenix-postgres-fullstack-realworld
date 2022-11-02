defmodule RealWorld.Repo.Migrations.AddFavoritesTable do
  use Ecto.Migration

  def change do
    create table("favorites", primary_key: false) do
      add :id, :uuid, primary_key: true
      add :user_id, references("users", type: :uuid), null: false
      add :article_id, references("articles", type: :uuid), null: false

      timestamps(type: :utc_datetime, updated_at: false)
    end

    create unique_index("favorites", [:user_id, :article_id])
  end
end
