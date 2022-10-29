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
      {:ok, token, _claims} = user |> RealWorldWeb.Guardian.encode_and_sign(%{})

      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.user_path(conn, :get_current_user))
      |> render("show.json", %{user: user, token: token})
    end
  end

  def get_current_user(conn, _params) do
    user = conn.private.guardian_default_resource
    token = conn.private.guardian_default_token

    render(conn, "show.json", %{user: user, token: token})
  end
end
