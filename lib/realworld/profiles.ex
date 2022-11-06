defmodule RealWorld.Profiles do
  @moduledoc """
  The Profiles context.
  """

  require Logger

  alias RealWorld.Profiles.Follow
  alias RealWorld.Repo
  alias RealWorld.Users

  def follow_user(follower_id, followed_id) do
    with {:ok, follower} <- Users.get_user_by_id(follower_id),
         {:ok, followed} <- Users.get_user_by_id(followed_id),
         {:ok, _} <-
           %Follow{}
           |> Follow.changeset(%{follower_id: follower.id, followed_id: followed.id})
           |> Repo.insert() do
      {:ok, nil}
    end
  end

  def unfollow_user(follower_id, followed_id) do
    with {:ok, is_following} <-
           is_following?(follower_id, followed_id) do
      if is_following do
        {:ok, _} =
          Repo.get_by!(Follow, follower_id: follower_id, followed_id: followed_id)
          |> Repo.delete()
      end

      {:ok, nil}
    end
  end

  def is_following?(follower_id, followed_id) do
    with {:ok, follower} <- Users.get_user_by_id(follower_id),
         {:ok, followed} <- Users.get_user_by_id(followed_id) do
      case Repo.get_by(Follow, follower_id: follower.id, followed_id: followed.id) do
        nil -> {:ok, false}
        _ -> {:ok, true}
      end
    end
  end
end
