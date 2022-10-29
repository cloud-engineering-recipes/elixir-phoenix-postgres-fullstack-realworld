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
    field :password, :string, virtual: true
    field :password_hash, :string
    field :bio, :string
    field :image, :string

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :username, :password_hash, :bio, :image])
    |> validate_required([:email, :username, :password_hash])
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
    |> unique_constraint(:username)
  end

  def creation_changeset(user, attrs) do
    user
    |> cast(attrs, [:password])
    |> validate_required([:password])
    |> validate_length(:password, min: 8)
    |> put_pass_hash()
  end

  defp put_pass_hash(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    change(changeset, Argon2.add_hash(password))
  end

  defp put_pass_hash(changeset), do: changeset
end
