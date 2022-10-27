defmodule RealWorldWeb.UserController do
  use RealWorldWeb, :controller

  alias RealWorld.Users
  alias RealWorldWeb.Guardian

  def register_user(
        conn,
        %{"user" => %{"email" => email, "username" => username, "password" => password}}
      ) do
    case Users.create_user(email, username, password) do
      {:ok, user} ->
        {:ok, token, _claims} = user |> Guardian.encode_and_sign(%{})

        conn
        |> put_status(:created)
        |> put_resp_header("location", Routes.user_path(conn, :get_current_user))
        |> render("show.json", %{user: user, token: token})
    end
  end

  def get_current_user(_conn, _params) do
  end
end
