defmodule RealWorld.Users.User do
  @moduledoc """
  The User model.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "users" do
    field :email, :string
    field :username, :string
    field :password_hash, :string
    field :bio, :string
    field :image, :string

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :username, :password_hash, :bio, :image])
    |> validate_required([:email, :username, :password_hash])
    |> unique_constraint(:email)
    |> unique_constraint(:username)
  end
end
