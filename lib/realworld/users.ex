defmodule RealWorld.Users do
  @moduledoc """
  The Users context.
  """

  require Logger

  alias RealWorld.Repo
  alias RealWorld.Users.User

  def create_user(%{email: email, username: username, password: _password} = attrs) do
    Logger.debug("create_user. email: #{email}, username: #{username}...")

    %User{}
    |> User.creation_changeset(attrs)
    |> User.changeset(attrs)
    |> Repo.insert()
  end

  def get_user_by_id(user_id) do
    Logger.debug("get_user_by_id #{user_id}...")

    case Repo.get(User, user_id) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end

  def get_user_by_email(email) do
    Logger.debug("get_user_by_email #{email}...")

    case Repo.get_by(User, email: email) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end

  def get_user_by_username(username) do
    Logger.debug("get_user_by_username #{username}...")

    case Repo.get_by(User, username: username) do
      nil -> {:error, :not_found}
      user -> {:ok, user}
    end
  end

  def update_user(user_id, attrs) do
    Logger.debug("update_user. user_id: #{user_id}...")

    with {:ok, user} <- get_user_by_id(user_id) do
      user
      |> User.update_changeset(attrs)
      |> User.changeset(attrs)
      |> Repo.update()
    end
  end

  def verify_password_by_email(email, password) do
    Logger.debug("verify_password_by_email. email: #{email}...")

    with {:ok, user} <- get_user_by_email(email) do
      {:ok, Argon2.verify_pass(password, user.password_hash)}
    end
  end
end
