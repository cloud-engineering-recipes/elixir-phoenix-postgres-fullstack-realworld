defmodule RealWorld.Repo.Migrations.AddUsersTable do
  use Ecto.Migration

  def change do
    create table("users", primary_key: false) do
      add :id, :uuid, primary_key: true
      add :email, :string, null: false
      add :username, :string, null: false
      add :password_hash, :string, null: false
      add :bio, :text
      add :image, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index("users", [:email])
    create unique_index("users", [:username])
  end
end
