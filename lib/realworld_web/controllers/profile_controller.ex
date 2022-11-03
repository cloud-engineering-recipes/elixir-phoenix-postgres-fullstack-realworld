defmodule RealWorldWeb.ProfileController do
  use RealWorldWeb, :controller

  require Logger

  alias RealWorld.Profiles
  alias RealWorld.Users

  action_fallback(RealWorldWeb.FallbackController)

  def follow_user(conn, %{"username" => followed_username}) do
    follower = conn.private.guardian_default_resource

    with {:ok, followed} <- Users.get_user_by_username(followed_username),
         {:ok, _} <-
           Profiles.follow_user(%{follower_id: follower.id, followed_id: followed.id}) do
      render(conn, "show.json", %{user: followed, is_following: true})
    end
  end

  def get_profile(conn, %{"username" => username}) do
    follower_id =
      if Map.has_key?(conn.private, :guardian_default_resource) do
        conn.private.guardian_default_resource.id
      else
        nil
      end

    with {:ok, user} <- Users.get_user_by_username(username) do
      is_following =
        if follower_id != nil do
          {:ok, is_following} =
            Profiles.is_following?(%{follower_id: follower_id, followed_id: user.id})

          is_following
        else
          false
        end

      render(conn, "show.json", %{user: user, is_following: is_following})
    end
  end

  def unfollow_user(conn, %{"username" => followed_username}) do
    follower = conn.private.guardian_default_resource

    with {:ok, followed} <- Users.get_user_by_username(followed_username),
         {:ok, _} <-
           Profiles.unfollow_user(%{follower_id: follower.id, followed_id: followed.id}) do
      render(conn, "show.json", %{user: followed, is_following: false})
    end
  end
end
