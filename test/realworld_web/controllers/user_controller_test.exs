defmodule RealWorldWeb.UserControllerTest do
  use RealWorldWeb.ConnCase

  import RealWorld.Factory

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json"), user: insert(:user)}
  end

  describe "register user" do
    test "renders user when data is valid", %{conn: conn} do
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

    test "renders errors when data is invalid", %{conn: conn} do
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
    test "renders user when user is authenticated", %{conn: conn, user: user} do
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

    test "renders errors when user is not found", %{conn: conn} do
      login_params = %{
        email: Faker.Internet.email(),
        password: List.to_string(Faker.Lorem.characters())
      }

      login_conn =
        conn
        |> post(Routes.user_path(conn, :login, user: login_params))

      assert json_response(login_conn, 401)["errors"]["body"] == ["unauthorized"]
    end

    test "renders errors when password doesn't match", %{conn: conn, user: user} do
      login_params = %{
        email: user.email,
        password: List.to_string(Faker.Lorem.characters())
      }

      login_conn =
        conn
        |> post(Routes.user_path(conn, :login, user: login_params))

      assert json_response(login_conn, 401)["errors"]["body"] == ["unauthorized"]
    end
  end

  describe "get current user" do
    test "renders user when user is found", %{conn: conn, user: user} do
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

    test "renders errors when bearer token is not sent", %{conn: conn} do
      get_current_user_conn =
        conn
        |> get(Routes.user_path(conn, :get_current_user))

      assert json_response(get_current_user_conn, 401)["errors"]["body"] == ["unauthorized"]
    end

    test "renders errors when user is not found", %{conn: conn} do
      token =
        "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJleGFtcGxlLmNvbSIsImV4cCI6MTY2NzAwMDMxNSwiaWF0IjoxNjY2OTk2NzE1LCJpc3MiOiJleGFtcGxlLmNvbSIsImp0aSI6IjI4YTdmNTA2LWFhODUtNDYwMS04ZTcwLTM1YmExMmY4YzgyOSIsIm5iZiI6MTY2Njk5NjcxNCwic3ViIjoiODgxMzc4MGItYjM1Ny00MzE4LTg0OGQtYzEwOTcxMmNkZTY3IiwidHlwIjoiYWNjZXNzIn0.LjUeJGhMbWxuCGjor0OU98q1ED7BTkIkU61NgFHvtXQwtAZMSNyt1qX8XRJVJukHLnFQ1PusN4RYqw_ESTZzrw"

      get_current_user_conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(Routes.user_path(conn, :get_current_user))

      assert json_response(get_current_user_conn, 401)["errors"]["body"] == ["unauthorized"]
    end
  end

  describe "update user" do
    test "renders user when the data is valid", %{conn: conn, user: user} do
      update_user_params = %{
        email: Faker.Internet.email(),
        username: Faker.Internet.user_name(),
        password: List.to_string(Faker.Lorem.characters()),
        bio: Faker.Lorem.paragraph(),
        image: Faker.Internet.url()
      }

      login_params = %{
        email: user.email,
        password: user.password
      }

      login_conn =
        conn
        |> post(Routes.user_path(conn, :login, user: login_params))

      assert %{"user" => logged_user} = json_response(login_conn, 200)

      update_user_conn =
        conn
        |> put_req_header("authorization", "Bearer #{logged_user["token"]}")
        |> get(Routes.user_path(conn, :update_user, user: update_user_params))

      assert %{"user" => updated_user} = json_response(update_user_conn, 200)

      get_current_user_conn =
        conn
        |> put_req_header("authorization", "Bearer #{updated_user["token"]}")
        |> get(Routes.user_path(conn, :get_current_user))

      assert %{"user" => found_user} = json_response(get_current_user_conn, 200)
      assert updated_user == found_user
    end

    test "renders errors when bearer token is not sent", %{conn: conn} do
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

      assert json_response(update_user_conn, 401)["errors"]["body"] == ["unauthorized"]
    end

    test "renders errors when user is not found", %{conn: conn} do
      update_user_params = %{
        email: Faker.Internet.email(),
        username: Faker.Internet.user_name(),
        password: List.to_string(Faker.Lorem.characters()),
        bio: Faker.Lorem.paragraph(),
        image: Faker.Internet.url()
      }

      token =
        "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJleGFtcGxlLmNvbSIsImV4cCI6MTY2NzAwMDMxNSwiaWF0IjoxNjY2OTk2NzE1LCJpc3MiOiJleGFtcGxlLmNvbSIsImp0aSI6IjI4YTdmNTA2LWFhODUtNDYwMS04ZTcwLTM1YmExMmY4YzgyOSIsIm5iZiI6MTY2Njk5NjcxNCwic3ViIjoiODgxMzc4MGItYjM1Ny00MzE4LTg0OGQtYzEwOTcxMmNkZTY3IiwidHlwIjoiYWNjZXNzIn0.LjUeJGhMbWxuCGjor0OU98q1ED7BTkIkU61NgFHvtXQwtAZMSNyt1qX8XRJVJukHLnFQ1PusN4RYqw_ESTZzrw"

      update_user_conn =
        conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> get(Routes.user_path(conn, :update_user, user: update_user_params))

      assert json_response(update_user_conn, 401)["errors"]["body"] == ["unauthorized"]
    end
  end
end
