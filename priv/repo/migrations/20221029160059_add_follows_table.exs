defmodule RealWorld.Repo.Migrations.AddFollowsTable do
  use Ecto.Migration

  def change do
    create table("follows", primary_key: false) do
      add :id, :uuid, primary_key: true
      add :follower_id, references("users", type: :uuid), null: false
      add :followed_id, references("users", type: :uuid), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index("follows", [:follower_id, :followed_id])
  end
end
