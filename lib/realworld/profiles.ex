defmodule RealWorld.Profiles do
  @moduledoc """
  The Profiles context.
  """

  require Logger

  alias RealWorld.Profiles.{Follow, Profile}
  alias RealWorld.Repo
  alias RealWorld.Users

  def follow_user(%{follower_id: follower_id, followed_id: followed_id}) do
    Logger.debug("follow_user. follower_id: #{follower_id}; followed_id: #{followed_id}...")

    with {:ok, follower} <- Users.get_user_by_id(follower_id),
         {:ok, followed} <- Users.get_user_by_id(followed_id),
         {:ok, _follow} <-
           %Follow{}
           |> Follow.changeset(%{follower_id: follower.id, followed_id: followed.id})
           |> Repo.insert() do
      Logger.debug(
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
end
