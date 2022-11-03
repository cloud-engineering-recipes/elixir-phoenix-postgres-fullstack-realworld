defmodule RealWorldWeb.UserController do
  use RealWorldWeb, :controller

  require Logger

  alias RealWorld.{Users, Users.User}

  action_fallback(RealWorldWeb.FallbackController)

  def register_user(
        conn,
        %{"user" => %{"email" => email, "username" => username, "password" => password}}
      ) do
    with {:ok, %User{} = user} <-
           Users.create_user(%{email: email, username: username, password: password}) do
      {:ok, token, _} = user |> RealWorldWeb.Guardian.encode_and_sign(%{})

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
    case Users.verify_password_by_email(email, password) do
      {:ok, true} ->
        {:ok, user} = Users.get_user_by_email(email)

        {:ok, token, _} = user |> RealWorldWeb.Guardian.encode_and_sign(%{})

        render(conn, "show.json", %{user: user, token: token})

      error ->
        Logger.error("Logging user error! email: #{email}; error: #{inspect(error)}")

        {:unauthorized, "Unauthorized"}
    end
  end

  def get_current_user(conn, _) do
    user = conn.private.guardian_default_resource

    token = conn.private.guardian_default_token

    render(conn, "show.json", %{user: user, token: token})
  end

  def update_user(conn, %{"user" => params}) do
    user = conn.private.guardian_default_resource

    token = conn.private.guardian_default_token

    with {:ok, %User{} = user} <- Users.update_user(user.id, params) do
      render(conn, "show.json", %{user: user, token: token})
    end
  end
end
