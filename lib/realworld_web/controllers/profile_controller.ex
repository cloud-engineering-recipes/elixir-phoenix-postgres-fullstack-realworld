defmodule RealWorldWeb.ProfileController do
  use RealWorldWeb, :controller

  require Logger

  alias RealWorld.Profiles
  alias RealWorld.Users

  action_fallback(RealWorldWeb.FallbackController)

  def follow_user(conn, %{"username" => followed_username}) do
    follower = conn.private.guardian_default_resource

    Logger.info(
      "Following user. follower_id: #{follower.id}; followed_username: #{followed_username}..."
    )

    case Users.get_user_by_username(followed_username) do
      {:ok, followed} ->
        with {:ok, profile} <-
               Profiles.follow_user(%{follower_id: follower.id, followed_id: followed.id}) do
          Logger.info(
            "Followed user! follower_id: #{follower.id}; followed_id: #{followed.id}..."
          )

          conn
          |> render("show.json", %{profile: profile})
        end

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> put_view(RealWorldWeb.ErrorView)
        |> render("404.json", %{error_messages: ["User #{followed_username} not found"]})
    end
  end

  def get_profile(conn, %{"username" => username}) do
    follower_id =
      if Map.has_key?(conn.private, :guardian_default_resource) do
        conn.private.guardian_default_resource.id
      else
        nil
      end

    Logger.debug("Getting profile. username: #{username}, follower_id: #{follower_id}...")

    case Users.get_user_by_username(username) do
      {:ok, user} ->
        with {:ok, profile} <-
               Profiles.get_profile(user.id, follower_id) do
          conn
          |> render("show.json", %{profile: profile})
        end

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> put_view(RealWorldWeb.ErrorView)
        |> render("404.json", %{error_messages: ["User #{username} not found"]})
    end
  end

  def unfollow_user(conn, %{"username" => followed_username}) do
    follower = conn.private.guardian_default_resource

    Logger.info(
      "Unfollowing user. follower_id: #{follower.id}; followed_username: #{followed_username}..."
    )

    case Users.get_user_by_username(followed_username) do
      {:ok, followed} ->
        with {:ok, profile} <-
               Profiles.unfollow_user(%{follower_id: follower.id, followed_id: followed.id}) do
          Logger.info(
            "Unfollowed user! follower_id: #{follower.id}; followed_id: #{followed.id}..."
          )

          conn
          |> render("show.json", %{profile: profile})
        end

      {:error, :not_found} ->
        conn
        |> put_status(:not_found)
        |> put_view(RealWorldWeb.ErrorView)
        |> render("404.json", %{error_messages: ["User #{followed_username} not found"]})
    end
  end
end
