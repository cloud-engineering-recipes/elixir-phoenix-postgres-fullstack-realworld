defmodule RealWorld.Articles.Favorite do
  @moduledoc """
  The Favorite model.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  schema "favorites" do
    field :user_id, :binary_id
    field :article_id, :binary_id

    timestamps(updated_at: false)
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:user_id, :article_id])
    |> validate_required([:user_id, :article_id])
    |> unique_constraint([:user_id, :article_id])
  end
end