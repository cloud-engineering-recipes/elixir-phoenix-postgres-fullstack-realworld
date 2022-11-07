defmodule RealWorldWeb.UserControllerTest do
  use RealWorldWeb.ConnCase

  import RealWorld.Factory
  import RealWorld.TestUtils

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "register user" do
    test "returns 201 and renders an user", %{conn: conn} do
      create_user_params = %{
        email: Faker.Internet.email(),
        username: Faker.Internet.user_name(),
        password: List.to_string(Faker.Lorem.characters())
      }

      register_user_conn =
        conn
        |> post(Routes.user_path(conn, :register_user), user: create_user_params)

      assert %{"user" => user} = json_response(register_user_conn, 201)
      assert user["email"] == create_user_params.email
      assert user["username"] == create_user_params.username
      assert user["token"] != nil
      assert user["bio"] == nil
      assert user["image"] == nil
    end

    test "returns 422 and renders errors when data is invalid", %{conn: conn} do
      create_user_params = %{
        email: "invalid",
        username: Faker.Internet.user_name(),
        password: List.to_string(Faker.Lorem.characters(1..7))
      }

      register_user_conn =
        conn
        |> post(Routes.user_path(conn, :register_user), user: create_user_params)

      assert length(json_response(register_user_conn, 422)["errors"]["body"]) > 0
    end
  end

  describe "login" do
    test "returns 200 and renders an user", %{conn: conn} do
      user = insert(:user)

      login_params = %{
        email: user.email,
        password: user.password
      }

      login_conn =
        conn
        |> post(Routes.user_path(conn, :login, user: login_params))

      assert %{"user" => logged_user} = json_response(login_conn, 200)

      get_current_user_conn =
        conn
        |> put_req_header("authorization", "Bearer #{logged_user["token"]}")
        |> get(Routes.user_path(conn, :get_current_user))

      assert %{"user" => found_user} = json_response(get_current_user_conn, 200)

      assert logged_user == found_user
    end

    test "returns 401 and renders errors when user is not found", %{conn: conn} do
      login_params = %{
        email: Faker.Internet.email(),
        password: List.to_string(Faker.Lorem.characters())
      }

      login_conn =
        conn
        |> post(Routes.user_path(conn, :login, user: login_params))

      assert json_response(login_conn, 401)["errors"]["body"] == ["Unauthorized"]
    end

    test "returns 401 and renders errors when password doesn't match", %{conn: conn} do
      user = insert(:user)

      login_params = %{
        email: user.email,
        password: List.to_string(Faker.Lorem.characters())
      }

      login_conn =
        conn
        |> post(Routes.user_path(conn, :login, user: login_params))

      assert json_response(login_conn, 401)["errors"]["body"] == ["Unauthorized"]
    end
  end

  describe "get current user" do
    test "returns 200 and renders the user", %{conn: conn} do
      user = insert(:user)

      get_current_user_conn =
        conn
        |> secure_conn(user.id)
        |> get(Routes.user_path(conn, :get_current_user))

      assert %{"user" => found_user} = json_response(get_current_user_conn, 200)
      assert found_user["username"] == user.username
      assert found_user["email"] == user.email
      assert found_user["token"] != nil
      assert found_user["bio"] == user.bio
      assert found_user["image"] == user.image
    end

    test "returns 401 and renders errors when bearer token is not sent", %{conn: conn} do
      get_current_user_conn =
        conn
        |> get(Routes.user_path(conn, :get_current_user))

      assert json_response(get_current_user_conn, 401)["errors"]["body"] == ["Unauthorized"]
    end

    test "returns 401 and renders errors when user is not found", %{conn: conn} do
      user_id = Faker.UUID.v4()

      get_current_user_conn =
        conn
        |> secure_conn(user_id)
        |> get(Routes.user_path(conn, :get_current_user))

      assert json_response(get_current_user_conn, 401)["errors"]["body"] == ["Unauthorized"]
    end
  end

  describe "update user" do
    test "returns 200 and renders the user", %{conn: conn} do
      user = insert(:user)

      update_user_params = %{
        email: Faker.Internet.email(),
        username: Faker.Internet.user_name(),
        password: List.to_string(Faker.Lorem.characters()),
        bio: Faker.Lorem.paragraph(),
        image: Faker.Internet.url()
      }

      update_user_conn =
        conn
        |> secure_conn(user.id)
        |> get(Routes.user_path(conn, :update_user, user: update_user_params))

      assert %{"user" => updated_user} = json_response(update_user_conn, 200)

      get_current_user_conn =
        conn
        |> put_req_header("authorization", "Bearer #{updated_user["token"]}")
        |> get(Routes.user_path(conn, :get_current_user))

      assert %{"user" => found_user} = json_response(get_current_user_conn, 200)
      assert updated_user == found_user
    end

    test "returns 401 and renders errors when bearer token is not sent", %{conn: conn} do
      update_user_params = %{
        email: Faker.Internet.email(),
        username: Faker.Internet.user_name(),
        password: List.to_string(Faker.Lorem.characters()),
        bio: Faker.Lorem.paragraph(),
        image: Faker.Internet.url()
      }

      update_user_conn =
        conn
        |> get(Routes.user_path(conn, :update_user, user: update_user_params))

      assert json_response(update_user_conn, 401)["errors"]["body"] == ["Unauthorized"]
    end

    test "returns 401 and renders errors when user is not found", %{conn: conn} do
      user_id = Faker.UUID.v4()

      update_user_params = %{
        email: Faker.Internet.email(),
        username: Faker.Internet.user_name(),
        password: List.to_string(Faker.Lorem.characters()),
        bio: Faker.Lorem.paragraph(),
        image: Faker.Internet.url()
      }

      update_user_conn =
        conn
        |> secure_conn(user_id)
        |> get(Routes.user_path(conn, :update_user, user: update_user_params))

      assert json_response(update_user_conn, 401)["errors"]["body"] == ["Unauthorized"]
    end
  end
end
