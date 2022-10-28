defmodule RealWorld.UsersTest do
  use RealWorld.DataCase, async: true

  import RealWorld.Factory
  import RealWorld.TestUtils
  alias RealWorld.{Users, Users.User}

  setup do
    {:ok, user: insert(:user)}
  end

  describe "users" do
    test "create_user/1 with valid data creates an user" do
      email = Faker.Internet.email()
      username = Faker.Internet.user_name()
      password = List.to_string(Faker.Lorem.characters())

      assert {:ok, %User{} = user} =
               Users.create_user(%{email: email, username: username, password: password})

      assert user.email == email
      assert user.username == username
      assert Argon2.verify_pass(password, user.password_hash)
      assert user.bio == nil
      assert user.image == nil

      found_user = Users.get_user_by_id!(user.id)

      assert user.id == found_user.id
      assert user.inserted_at == found_user.inserted_at
      assert user.updated_at == found_user.updated_at
      assert user.password_hash == found_user.password_hash
    end

    test "create_user/1 with invalid email returns an error changeset" do
      email = "invalid"
      username = Faker.Internet.user_name()
      password = List.to_string(Faker.Lorem.characters())

      assert {:error, %Ecto.Changeset{} = changeset} =
               Users.create_user(%{email: email, username: username, password: password})

      assert "has invalid format" in errors_on(changeset, :email)
    end

    test "create_user/1 with password with length less than 8 returns an error changeset" do
      email = Faker.Internet.email()
      username = Faker.Internet.user_name()
      password = "Pass@12"

      assert {:error, %Ecto.Changeset{} = changeset} =
               Users.create_user(%{email: email, username: username, password: password})

      assert "should be at least 8 character(s)" in errors_on(changeset, :password)
    end

    test "get_user_by_id!/1 returns the user with given id",
         %{user: user} do
      found_user = Users.get_user_by_id!(user.id)

      assert found_user == user
    end
  end
end
