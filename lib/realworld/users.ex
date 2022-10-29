defmodule RealWorld.Users do
  @moduledoc """
  The Users context.
  """

  alias RealWorld.Repo
  alias RealWorld.Users.User

  def create_user(%{email: _email, username: _username, password: _password} = attrs) do
    %User{}
    |> User.creation_changeset(attrs)
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def get_user_by_id(user_id) do
    User
    |> Repo.get(user_id)
  end

  def get_user_by_email(email) do
    User
    |> Repo.get_by(email: email)
  end

  def verify_password_by_email(email, password) do
    case get_user_by_email(email) do
      nil -> {:error, :not_found}
      user -> {:ok, Argon2.verify_pass(password, user.password_hash)}
    end
  end
end
