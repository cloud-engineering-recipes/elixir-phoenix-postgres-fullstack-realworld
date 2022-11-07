defmodule RealWorld.Repo.Migrations.AddFavoritesTable do
  use Ecto.Migration

  def change do
    create table("favorites", primary_key: false) do
      add :user_id, references("users", type: :uuid), primary_key: true
      add :article_id, references("articles", type: :uuid), primary_key: true

      timestamps(type: :utc_datetime, updated_at: false)
    end
  end
end
