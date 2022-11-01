defmodule RealWorld.UsersTest do
  use RealWorld.DataCase, async: true

  import RealWorld.Factory
  import RealWorld.TestUtils
  alias RealWorld.{Users, Users.User}

  setup do
    {:ok, user: insert(:user)}
  end

  describe "create_user/1" do
    test "creates and returns an user" do
      create_user_attrs = %{
        email: Faker.Internet.email(),
        username: Faker.Internet.user_name(),
        password: List.to_string(Faker.Lorem.characters())
      }

      assert {:ok, %User{} = user} = Users.create_user(create_user_attrs)

      assert user.email == create_user_attrs.email
      assert user.username == create_user_attrs.username
      assert Argon2.verify_pass(create_user_attrs.password, user.password_hash)
      assert user.bio == nil
      assert user.image == nil

      with {:ok, %User{} = found_user} <- Users.get_user_by_id(user.id) do
        assert user.id == found_user.id
        assert user.password_hash == found_user.password_hash
        assert found_user.password == nil
        assert user.inserted_at == found_user.inserted_at
        assert user.updated_at == found_user.updated_at
      end
    end

    test "returns an error changeset when email is invalid" do
      create_user_attrs = %{
        email: "invalid",
        username: Faker.Internet.user_name(),
        password: List.to_string(Faker.Lorem.characters())
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Users.create_user(create_user_attrs)

      assert "has invalid format" in errors_on(changeset, :email)
    end

    test "returns an error changeset when email is already taken", %{user: existing_user} do
      create_user_attrs = %{
        email: existing_user.email,
        username: Faker.Internet.user_name(),
        password: List.to_string(Faker.Lorem.characters())
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Users.create_user(create_user_attrs)

      assert "has already been taken" in errors_on(changeset, :email)
    end

    test "returns an error changeset when username is already taken", %{user: existing_user} do
      create_user_attrs = %{
        email: Faker.Internet.email(),
        username: existing_user.username,
        password: List.to_string(Faker.Lorem.characters())
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Users.create_user(create_user_attrs)

      assert "has already been taken" in errors_on(changeset, :username)
    end

    test "returns an error changeset when password contains less than 8 characters" do
      create_user_attrs = %{
        email: Faker.Internet.email(),
        username: Faker.Internet.user_name(),
        password: List.to_string(Faker.Lorem.characters(1..7))
      }

      assert {:error, %Ecto.Changeset{} = changeset} = Users.create_user(create_user_attrs)

      assert "should be at least 8 character(s)" in errors_on(changeset, :password)
    end
  end

  describe "get_user_by_id/1" do
    test "returns the user",
         %{user: user} do
      with {:ok, %User{} = found_user} <- Users.get_user_by_id(user.id) do
        assert found_user == %{user | password: nil}
      end
    end

    test "returns :not_found when the user is not found" do
      user_id = Faker.UUID.v4()

      assert {:not_found, "User #{user_id} not found"} ==
               Users.get_user_by_id(user_id)
    end
  end

  describe "get_user_by_email/1" do
    test "returns the user",
         %{user: user} do
      with {:ok, %User{} = found_user} <- Users.get_user_by_email(user.email) do
        assert found_user == %{user | password: nil}
      end
    end

    test "returns :not_found when the user is not found" do
      email = Faker.Internet.email()

      assert {:not_found, "Email #{email} not found"} ==
               Users.get_user_by_email(email)
    end
  end

  describe "get_user_by_username/1" do
    test "returns the user",
         %{user: user} do
      with {:ok, %User{} = found_user} <- Users.get_user_by_username(user.username) do
        assert found_user == %{user | password: nil}
      end
    end

    test "returns :not_found when the user is not found" do
      username = Faker.Internet.user_name()

      assert {:not_found, "Username #{username} not found"} ==
               Users.get_user_by_username(username)
    end
  end

  describe "update_user/2" do
    test "updates and returns the user", %{
      user: user
    } do
      update_user_attrs = %{
        email: Faker.Internet.email(),
        username: Faker.Internet.user_name(),
        password: List.to_string(Faker.Lorem.characters()),
        bio: Faker.Lorem.paragraph(),
        image: Faker.Internet.url()
      }

      assert {:ok, updated_user} = Users.update_user(user.id, update_user_attrs)
      assert updated_user.id == user.id
      assert updated_user.email == update_user_attrs.email
      assert Argon2.verify_pass(update_user_attrs.password, updated_user.password_hash)
      assert updated_user.bio == update_user_attrs.bio
      assert updated_user.image == update_user_attrs.image

      with {:ok, %User{} = found_user} <- Users.get_user_by_id(updated_user.id) do
        assert updated_user == found_user
      end
    end

    test "returns an error changeset when email is invalid", %{user: user} do
      update_user_attrs = %{
        email: "invalid"
      }

      assert {:error, %Ecto.Changeset{} = changeset} =
               Users.update_user(user.id, update_user_attrs)

      assert "has invalid format" in errors_on(changeset, :email)
    end

    test "returns an error changeset when email is already taken", %{user: existing_user} do
      user = insert(:user)

      update_user_attrs = %{
        email: existing_user.email
      }

      assert {:error, %Ecto.Changeset{} = changeset} =
               Users.update_user(user.id, update_user_attrs)

      assert "has already been taken" in errors_on(changeset, :email)
    end

    test "returns an error changeset when username is already taken", %{user: existing_user} do
      user = insert(:user)

      update_user_attrs = %{
        username: existing_user.username
      }

      assert {:error, %Ecto.Changeset{} = changeset} =
               Users.update_user(user.id, update_user_attrs)

      assert "has already been taken" in errors_on(changeset, :username)
    end

    test "returns an error changeset when password contains less than 8 characters", %{
      user: user
    } do
      update_user_attrs = %{
        password: List.to_string(Faker.Lorem.characters(1..7))
      }

      assert {:error, %Ecto.Changeset{} = changeset} =
               Users.update_user(user.id, update_user_attrs)

      assert "should be at least 8 character(s)" in errors_on(changeset, :password)
    end
  end

  describe "verify_password_by_email/2" do
    test "returns true when password matches" do
      create_user_attrs = %{
        email: Faker.Internet.email(),
        username: Faker.Internet.user_name(),
        password: List.to_string(Faker.Lorem.characters())
      }

      assert {:ok, %User{} = user} = Users.create_user(create_user_attrs)

      assert {:ok, password_matches} =
               Users.verify_password_by_email(user.email, create_user_attrs.password)

      assert password_matches
    end

    test "returns false when password doesn't match", %{
      user: user
    } do
      password = List.to_string(Faker.Lorem.characters())

      assert {:ok, password_matches} = Users.verify_password_by_email(user.email, password)
      assert !password_matches
    end

    test "returns :not_found when user is not found" do
      email = Faker.Internet.email()
      password = List.to_string(Faker.Lorem.characters())

      assert {:not_found, "Email #{email} not found"} ==
               Users.verify_password_by_email(email, password)
    end
  end
end
