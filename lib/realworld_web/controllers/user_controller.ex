defmodule RealWorldWeb.UserController do
  use RealWorldWeb, :controller

  require Logger

  alias RealWorld.{Users, Users.User}

  action_fallback(RealWorldWeb.FallbackController)

  def register_user(
        conn,
        %{"user" => %{"email" => email, "username" => username, "password" => password}}
      ) do
    Logger.info("Registering user. email: #{email}; username: #{username}...")

    with {:ok, %User{} = user} <-
           Users.create_user(%{email: email, username: username, password: password}) do
      Logger.info("User registered!. email: #{email}; username: #{username}")
      {:ok, token, _claims} = user |> RealWorldWeb.Guardian.encode_and_sign(%{})

      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.user_path(conn, :get_current_user))
      |> render("show.json", %{user: user, token: token})
    end
  end

  def login(
        conn,
        %{"user" => %{"email" => email, "password" => password}}
      ) do
    Logger.info("Logging user. email: #{email}....")

    case Users.verify_password_by_email(email, password) do
      {:ok, true} ->
        {:ok, user} = Users.get_user_by_email(email)
        {:ok, token, _claims} = user |> RealWorldWeb.Guardian.encode_and_sign(%{})

        Logger.info("User logged in! email: #{email}....")

        render(conn, "show.json", %{user: user, token: token})

      error ->
        Logger.error("Logging user error! email: #{email}; error: #{inspect(error)}")
        {:error, :unauthorized}
    end
  end

  def get_current_user(conn, _params) do
    user = conn.private.guardian_default_resource
    token = conn.private.guardian_default_token

    Logger.debug("Got user! user_id: #{user.id}")

    render(conn, "show.json", %{user: user, token: token})
  end

  def update_user(conn, %{"user" => user_params}) do
    user = conn.private.guardian_default_resource
    token = conn.private.guardian_default_token

    Logger.info("Updating user. user_id: #{user.id}...")

    with {:ok, %User{} = user} <- Users.update_user(user.id, user_params) do
      Logger.info("Updated user! user_id: #{user.id}...")
      render(conn, "show.json", %{user: user, token: token})
    end
  end
end
