defmodule RealWorld.UsersTest do
  use RealWorld.DataCase, async: true

  import RealWorld.Factory
  alias RealWorld.{Users, Users.User}

  setup do
    {:ok, user: insert(:user)}
  end

  describe "users" do
    test "create_user/1 with valid data creates an user" do
      email = "foo@example.com"
      username = "foo"
      password = "Pass@123"

      assert {:ok, %User{} = user} =
               Users.create_user(%{email: email, username: username, password: password})

      assert user.email == email
      assert user.username == username
      assert Argon2.verify_pass(password, user.password_hash)
      assert user.bio == nil
      assert user.image == nil
      assert user == Users.get_user_by_id!(user.id)
    end

    test "get_user_by_id!/1 returns the user with given id",
         %{user: user} do
      found_user = Users.get_user_by_id!(user.id)

      assert found_user == user
    end
  end
end
