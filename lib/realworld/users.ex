defmodule RealWorld.Users do
  @moduledoc """
  The Users context.
  """

  alias RealWorld.Repo
  alias RealWorld.Users.User

  def create_user(attrs = %{email: _email, username: _username, password: _password}) do
    %User{}
    |> User.creation_changeset(attrs)
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def get_user_by_id!(id) do
    User
    |> Repo.get!(id)
  end
end
