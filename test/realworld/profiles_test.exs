defmodule RealWorld.ProfilesTest do
  use RealWorld.DataCase, async: true

  import RealWorld.Factory
  alias RealWorld.Profiles

  setup do
    {:ok, follower: insert(:user), followed: insert(:user)}
  end

  describe "follow_user/1" do
    test "follows an user", %{follower: follower, followed: followed} do
      assert {:ok, nil} =
               Profiles.follow_user(%{follower_id: follower.id, followed_id: followed.id})

      with {:ok, is_following} <-
             Profiles.is_following?(%{follower_id: follower.id, followed_id: followed.id}) do
        assert is_following
      end
    end

    test "returns :not_found when the follower is not found", %{followed: followed} do
      follower_id = Faker.UUID.v4()

      assert {:not_found, "User #{follower_id} not found"} ==
               Profiles.follow_user(%{follower_id: follower_id, followed_id: followed.id})
    end

    test "returns :not_found when the followed is not found", %{follower: follower} do
      followed_id = Faker.UUID.v4()

      assert {:not_found, "User #{followed_id} not found"} ==
               Profiles.follow_user(%{follower_id: follower.id, followed_id: followed_id})
    end
  end

  describe "unfollow_user/1" do
    test "unfollows an user", %{
      follower: follower,
      followed: followed
    } do
      assert {:ok, _} =
               Profiles.follow_user(%{follower_id: follower.id, followed_id: followed.id})

      assert {:ok, nil} =
               Profiles.unfollow_user(%{follower_id: follower.id, followed_id: followed.id})

      with {:ok, is_following} <-
             Profiles.is_following?(%{follower_id: follower.id, followed_id: followed.id}) do
        assert !is_following
      end
    end

    test "does nothing when the user is not followed", %{
      follower: follower,
      followed: followed
    } do
      assert {:ok, nil} =
               Profiles.unfollow_user(%{follower_id: follower.id, followed_id: followed.id})

      with {:ok, is_following} <-
             Profiles.is_following?(%{follower_id: follower.id, followed_id: followed.id}) do
        assert !is_following
      end
    end

    test "returns :not_found when the follower is not found", %{
      followed: followed
    } do
      follower_id = Faker.UUID.v4()

      assert {:not_found, "User #{follower_id} not found"} ==
               Profiles.unfollow_user(%{follower_id: follower_id, followed_id: followed.id})
    end

    test "returns :not_found when the followed is not found", %{
      follower: follower
    } do
      followed_id = Faker.UUID.v4()

      assert {:not_found, "User #{followed_id} not found"} ==
               Profiles.unfollow_user(%{follower_id: follower.id, followed_id: followed_id})
    end
  end
end
