defmodule RealWorldWeb.ProfileController do
  use RealWorldWeb, :controller

  require Logger

  alias RealWorld.Profiles
  alias RealWorld.Users
  alias RealWorldWeb.Dtos.ProfileDto

  action_fallback(RealWorldWeb.FallbackController)

  def follow_user(conn, %{"username" => followed_username}) do
    follower = conn.private.guardian_default_resource

    with {:ok, followed} <- Users.get_user_by_username(followed_username),
         {:ok, _} <-
           Profiles.follow_user(%{follower_id: follower.id, followed_id: followed.id}) do
      profile_dto = %ProfileDto{
        username: followed.username,
        bio: followed.bio,
        image: followed.image,
        following: true
      }

      conn
      |> render("show.json", %{profile: profile_dto})
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

      profile_dto = %ProfileDto{
        username: user.username,
        bio: user.bio,
        image: user.image,
        following: is_following
      }

      conn
      |> render("show.json", %{profile: profile_dto})
    end
  end

  def unfollow_user(conn, %{"username" => followed_username}) do
    follower = conn.private.guardian_default_resource

    with {:ok, followed} <- Users.get_user_by_username(followed_username),
         {:ok, _} <-
           Profiles.unfollow_user(%{follower_id: follower.id, followed_id: followed.id}) do
      profile_dto = %ProfileDto{
        username: followed.username,
        bio: followed.bio,
        image: followed.image,
        following: false
      }

      conn
      |> render("show.json", %{profile: profile_dto})
    end
  end
end
