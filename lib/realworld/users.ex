defmodule RealWorld.Users do
  @moduledoc """
  The Users context.
  """

  alias RealWorld.Repo
  alias RealWorld.Users.User

  def create_user(%{email: email, username: username, password: password}) do
    %User{}
    |> User.changeset(%{
      email: email,
      username: username,
      password_hash: Argon2.hash_pwd_salt(password)
    })
    |> Repo.insert()
  end

  def get_user_by_id!(id) do
    User
    |> Repo.get!(id)
  end
end
