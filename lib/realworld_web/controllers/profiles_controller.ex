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

    with {:ok, followed} <- Users.get_user_by_username(followed_username),
         {:ok, profile} <-
           Profiles.follow_user(%{follower_id: follower.id, followed_id: followed.id}) do
      Logger.info("Followed user! follower_id: #{follower.id}; followed_id: #{followed.id}...")

      conn
      |> render("show.json", %{profile: profile})
    end
  end
end
