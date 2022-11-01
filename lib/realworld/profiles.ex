defmodule RealWorld.Profiles do
  @moduledoc """
  The Profiles context.
  """

  require Logger

  alias RealWorld.Profiles.{Follow, Profile}
  alias RealWorld.Repo
  alias RealWorld.Users

  def follow_user(%{follower_id: follower_id, followed_id: followed_id}) do
    Logger.info("follow_user. follower_id: #{follower_id}; followed_id: #{followed_id}...")

    with {:ok, follower} <- Users.get_user_by_id(follower_id),
         {:ok, followed} <- Users.get_user_by_id(followed_id),
         {:ok, _follow} <-
           %Follow{}
           |> Follow.changeset(%{follower_id: follower.id, followed_id: followed.id})
           |> Repo.insert() do
      Logger.info(
        "follow_user successful! follower_id: #{follower_id}; followed_id: #{followed_id}"
      )

      {:ok,
       %Profile{
         username: followed.username,
         bio: followed.bio,
         image: followed.image,
         following: true
       }}
    end
  end

  def get_profile(user_id, follower_id \\ nil) do
    Logger.debug("get_profile. user_id: #{user_id}; follower_id: #{follower_id}...")

    with {:ok, user} <- Users.get_user_by_id(user_id),
         profile <- %Profile{
           username: user.username,
           bio: user.bio,
           image: user.image,
           following: false
         } do
      if follower_id != nil do
        with {:ok, following} <- is_following?(follower_id, user.id) do
          {:ok, %{profile | following: following}}
        end
      else
        {:ok, profile}
      end
    end
  end

  def unfollow_user(%{follower_id: follower_id, followed_id: followed_id}) do
    Logger.info("unfollow_user. follower_id: #{follower_id}; followed_id: #{followed_id}...")

    with {:ok, profile} <- get_profile(followed_id, follower_id) do
      if profile.following do
        {:ok, _follow} =
          Repo.get_by!(Follow, follower_id: follower_id, followed_id: followed_id)
          |> Repo.delete()
      end

      Logger.info(
        "unfollow_user successful!. follower_id: #{follower_id}; followed_id: #{followed_id}"
      )

      {:ok, %{profile | following: false}}
    end
  end

  defp is_following?(follower_id, followed_id) do
    with {:ok, follower} <- Users.get_user_by_id(follower_id),
         {:ok, followed} <- Users.get_user_by_id(followed_id) do
      case Repo.get_by(Follow, follower_id: follower.id, followed_id: followed.id) do
        nil -> {:ok, false}
        _ -> {:ok, true}
      end
    end
  end
end
