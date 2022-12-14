defmodule RealWorld.Users do
  @moduledoc """
  The Users context.
  """

  require Logger

  alias RealWorld.Repo
  alias RealWorld.Users.User

  def create_user(attrs) do
    %User{}
    |> User.creation_changeset(attrs)
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def get_user_by_id(user_id) do
    case Repo.get(User, user_id) do
      nil -> {:not_found, "user #{user_id} not found"}
      user -> {:ok, user}
    end
  end

  def get_user_by_email(email) do
    case Repo.get_by(User, email: email) do
      nil -> {:not_found, "email #{email} not found"}
      user -> {:ok, user}
    end
  end

  def get_user_by_username(username) do
    case Repo.get_by(User, username: username) do
      nil -> {:not_found, "username #{username} not found"}
      user -> {:ok, user}
    end
  end

  def update_user(user_id, attrs) do
    with {:ok, user} <- get_user_by_id(user_id) do
      user
      |> User.update_changeset(attrs)
      |> User.changeset(attrs)
      |> Repo.update()
    end
  end

  def verify_password_by_email(email, password) do
    with {:ok, user} <- get_user_by_email(email) do
      {:ok, Argon2.verify_pass(password, user.password_hash)}
    end
  end
end
