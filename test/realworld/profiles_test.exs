defmodule RealWorld.ProfilesTest do
  use RealWorld.DataCase, async: true

  import RealWorld.Factory
  alias RealWorld.Profiles

  describe "follow_user/2" do
    test "follows an user" do
      follower = insert(:user)
      followed = insert(:user)

      assert {:ok, nil} = Profiles.follow_user(follower.id, followed.id)

      with {:ok, is_following} <-
             Profiles.is_following?(follower.id, followed.id) do
        assert is_following
      end
    end

    test "returns :not_found when the follower is not found" do
      follower_id = Faker.UUID.v4()
      followed = insert(:user)

      assert {:not_found, "user #{follower_id} not found"} ==
               Profiles.follow_user(follower_id, followed.id)
    end

    test "returns :not_found when the followed is not found" do
      follower = insert(:user)
      followed_id = Faker.UUID.v4()

      assert {:not_found, "user #{followed_id} not found"} ==
               Profiles.follow_user(follower.id, followed_id)
    end
  end

  describe "unfollow_user/2" do
    test "unfollows an user" do
      follower = insert(:user)
      followed = insert(:user)

      assert {:ok, _} = Profiles.follow_user(follower.id, followed.id)

      assert {:ok, nil} =
               Profiles.unfollow_user(
                 follower.id,
                 followed.id
               )

      with {:ok, is_following} <-
             Profiles.is_following?(follower.id, followed.id) do
        assert !is_following
      end
    end

    test "does nothing when the user is not followed" do
      follower = insert(:user)
      followed = insert(:user)

      assert {:ok, nil} =
               Profiles.unfollow_user(
                 follower.id,
                 followed.id
               )

      with {:ok, is_following} <-
             Profiles.is_following?(follower.id, followed.id) do
        assert !is_following
      end
    end

    test "returns :not_found when the follower is not found" do
      follower_id = Faker.UUID.v4()
      followed = insert(:user)

      assert {:not_found, "user #{follower_id} not found"} ==
               Profiles.unfollow_user(
                 follower_id,
                 followed.id
               )
    end

    test "returns :not_found when the followed is not found" do
      follower = insert(:user)
      followed_id = Faker.UUID.v4()

      assert {:not_found, "user #{followed_id} not found"} ==
               Profiles.unfollow_user(follower.id, followed_id)
    end
  end
end
