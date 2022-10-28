defmodule RealWorldWeb.ArticleControllerTest do
  use RealWorldWeb.ConnCase

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "register user" do
    test "renders user when data is valid", %{conn: conn} do
      create_attrs = %{
        email: Faker.Internet.email(),
        username: Faker.Internet.user_name(),
        password: List.to_string(Faker.Lorem.characters())
      }

      register_user_conn =
        conn
        |> post(Routes.user_path(conn, :register_user), user: create_attrs)

      assert %{"user" => user} = json_response(register_user_conn, 201)
      assert Map.get(user, "email") == create_attrs.email
      assert Map.get(user, "username") == create_attrs.username
      assert Map.get(user, "token") != nil
      assert Map.get(user, "bio") == nil
      assert Map.get(user, "image") == nil

      get_current_user_conn =
        conn
        |> put_req_header("authorization", "Bearer #{Map.get(user, "token")}")
        |> get(Routes.user_path(conn, :get_current_user))

      assert %{"user" => found_user} = json_response(get_current_user_conn, 200)
      assert user == found_user
    end

    test "renders errors when data is invalid", %{conn: conn} do
      invalid_attrs = %{
        email: "invalid",
        username: Faker.Internet.user_name(),
        password: List.to_string(Faker.Lorem.characters(1..7))
      }

      register_user_conn =
        conn
        |> post(Routes.user_path(conn, :register_user), user: invalid_attrs)

      assert length(json_response(register_user_conn, 422)["errors"]["body"]) > 0
    end
  end
end
