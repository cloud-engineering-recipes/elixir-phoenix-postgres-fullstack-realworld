defmodule RealWorldWeb.UserController do
  use RealWorldWeb, :controller

  require Logger

  alias RealWorld.{Users, Users.User}
  alias RealWorldWeb.Dtos.UserDto

  action_fallback(RealWorldWeb.FallbackController)

  def register_user(
        conn,
        %{"user" => %{"email" => email, "username" => username, "password" => password}}
      ) do
    with {:ok, %User{} = user} <-
           Users.create_user(%{email: email, username: username, password: password}) do
      {:ok, token, _claims} = user |> RealWorldWeb.Guardian.encode_and_sign(%{})

      user_dto = %UserDto{
        email: user.email,
        username: user.username,
        token: token,
        bio: nil,
        image: nil
      }

      conn
      |> put_status(:created)
      |> put_resp_header("location", Routes.user_path(conn, :get_current_user))
      |> render("show.json", %{user: user_dto})
    end
  end

  def login(
        conn,
        %{"user" => %{"email" => email, "password" => password}}
      ) do
    case Users.verify_password_by_email(email, password) do
      {:ok, true} ->
        {:ok, user} = Users.get_user_by_email(email)

        {:ok, token, _claims} = user |> RealWorldWeb.Guardian.encode_and_sign(%{})

        user_dto = %UserDto{
          email: user.email,
          username: user.username,
          token: token,
          bio: user.bio,
          image: user.image
        }

        render(conn, "show.json", %{user: user_dto})

      error ->
        Logger.error("Logging user error! email: #{email}; error: #{inspect(error)}")

        {:unauthorized, "Unauthorized"}
    end
  end

  def get_current_user(conn, _params) do
    user = conn.private.guardian_default_resource

    token = conn.private.guardian_default_token

    user_dto = %UserDto{
      email: user.email,
      username: user.username,
      token: token,
      bio: user.bio,
      image: user.image
    }

    render(conn, "show.json", %{user: user_dto})
  end

  def update_user(conn, %{"user" => params}) do
    user = conn.private.guardian_default_resource

    token = conn.private.guardian_default_token

    with {:ok, %User{} = user} <- Users.update_user(user.id, params) do
      user_dto = %UserDto{
        email: user.email,
        username: user.username,
        token: token,
        bio: user.bio,
        image: user.image
      }

      render(conn, "show.json", %{user: user_dto})
    end
  end
end
