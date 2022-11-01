defmodule RealWorld.ProfilesTest do
  use RealWorld.DataCase, async: true

  import RealWorld.Factory
  alias RealWorld.{Profiles, Profiles.Profile}

  setup do
    {:ok, follower: insert(:user), followed: insert(:user)}
  end

  describe "follow_user/1" do
    test "follows an user and returns his/her profile", %{follower: follower, followed: followed} do
      assert {:ok, %Profile{} = profile} =
               Profiles.follow_user(%{follower_id: follower.id, followed_id: followed.id})

      assert profile.username == followed.username
      assert profile.bio == followed.bio
      assert profile.image == followed.image
      assert profile.following

      with {:ok, %Profile{} = found_profile} <- Profiles.get_profile(followed.id, follower.id) do
        assert profile == found_profile
      end
    end

    test "returns :not_found when the follower is not found", %{followed: followed} do
      follower_id = Faker.UUID.v4()

      assert {:error, :not_found} =
               Profiles.follow_user(%{follower_id: follower_id, followed_id: followed.id})
    end

    test "returns :not_found when the followed is not found", %{follower: follower} do
      followed_id = Faker.UUID.v4()

      assert {:error, :not_found} =
               Profiles.follow_user(%{follower_id: follower.id, followed_id: followed_id})
    end
  end

  describe "get_profile/2" do
    test "returns a profile with :following false when follower id is nil", %{followed: user} do
      with {:ok, %Profile{} = profile} <- Profiles.get_profile(user.id) do
        assert profile.username == user.username
        assert profile.bio == user.bio
        assert profile.image == user.image
        assert !profile.following
      end
    end

    test "returns a profile with :following true when given a follower id and the user is followed",
         %{follower: follower, followed: followed} do
      assert {:ok, _} =
               Profiles.follow_user(%{follower_id: follower.id, followed_id: followed.id})

      with {:ok, %Profile{} = profile} <- Profiles.get_profile(followed.id, follower.id) do
        assert profile.username == followed.username
        assert profile.bio == followed.bio
        assert profile.image == followed.image
        assert profile.following
      end
    end

    test "returns a profile with :following false when given a follower id and the user is not followed",
         %{follower: follower, followed: followed} do
      with {:ok, %Profile{} = profile} <- Profiles.get_profile(followed.id, follower.id) do
        assert profile.username == followed.username
        assert profile.bio == followed.bio
        assert profile.image == followed.image
        assert !profile.following
      end
    end

    test "returns :not_found when the user not found" do
      user_id = Faker.UUID.v4()

      assert {:error, :not_found} = Profiles.get_profile(user_id)
    end

    test "returns :not_found when given a follower id and the follower is not found", %{
      followed: followed
    } do
      follower_id = Faker.UUID.v4()

      assert {:error, :not_found} = Profiles.get_profile(followed.id, follower_id)
    end
  end

  describe "unfollow_user/1" do
    test "returns a profile with :following false when user is followed", %{
      follower: follower,
      followed: followed
    } do
      assert {:ok, _} =
               Profiles.follow_user(%{follower_id: follower.id, followed_id: followed.id})

      assert {:ok, %Profile{} = profile} =
               Profiles.unfollow_user(%{follower_id: follower.id, followed_id: followed.id})

      assert profile.username == followed.username
      assert profile.bio == followed.bio
      assert profile.image == followed.image
      assert !profile.following

      assert {:ok, got_profile} = Profiles.get_profile(followed.id, follower.id)

      assert profile == got_profile
    end

    test "returns a profile with :following false when user is not followed", %{
      follower: follower,
      followed: followed
    } do
      assert {:ok, %Profile{} = profile} =
               Profiles.unfollow_user(%{follower_id: follower.id, followed_id: followed.id})

      assert profile.username == followed.username
      assert profile.bio == followed.bio
      assert profile.image == followed.image
      assert !profile.following

      assert {:ok, got_profile} = Profiles.get_profile(followed.id, follower.id)

      assert profile == got_profile
    end

    test "returns :not_found when the follower is not found", %{
      followed: followed
    } do
      follower_id = Faker.UUID.v4()

      assert {:error, :not_found} =
               Profiles.unfollow_user(%{follower_id: follower_id, followed_id: followed.id})
    end

    test "returns :not_found when the followed is not found", %{
      follower: follower
    } do
      followed_id = Faker.UUID.v4()

      assert {:error, :not_found} =
               Profiles.unfollow_user(%{follower_id: follower.id, followed_id: followed_id})
    end
  end
end
