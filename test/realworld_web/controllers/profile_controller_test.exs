defmodule RealWorldWeb.ProfileControllerTest do
  use RealWorldWeb.ConnCase

  import RealWorld.Factory
  import RealWorld.TestUtils

  setup %{conn: conn} do
    {:ok,
     conn: put_req_header(conn, "accept", "application/json"),
     follower: insert(:user),
     followed: insert(:user)}
  end

  describe "follow user" do
    test "returns 200 and renders profile", %{
      conn: conn,
      follower: follower,
      followed: followed
    } do
      follow_user_conn =
        conn
        |> secure_conn(follower.id)
        |> post(Routes.profile_path(conn, :follow_user, followed.username))

      assert %{"profile" => profile} = json_response(follow_user_conn, 200)
      assert profile["username"] == followed.username
      assert profile["bio"] == followed.bio
      assert profile["image"] == followed.image
      assert profile["following"]
    end

    test "returns 401 and renders errors when bearer token is not sent", %{
      conn: conn,
      followed: followed
    } do
      follow_user_conn =
        conn
        |> post(Routes.profile_path(conn, :follow_user, followed.username))

      assert json_response(follow_user_conn, 401)["errors"]["body"] == [
               "Unauthorized"
             ]
    end

    test "returns 401 and renders errors when follower is not found", %{
      conn: conn,
      followed: followed
    } do
      user_id = Faker.UUID.v4()

      follow_user_conn =
        conn
        |> secure_conn(user_id)
        |> post(Routes.profile_path(conn, :follow_user, followed.username))

      assert json_response(follow_user_conn, 401)["errors"]["body"] == [
               "Unauthorized"
             ]
    end

    test "returns 404 and renders errors when followed is not found", %{
      conn: conn,
      follower: follower
    } do
      followed_username = Faker.Internet.user_name()

      follow_user_conn =
        conn
        |> secure_conn(follower.id)
        |> post(Routes.profile_path(conn, :follow_user, followed_username))

      assert json_response(follow_user_conn, 404)["errors"]["body"] == [
               "User #{followed_username} not found"
             ]
    end
  end

  describe "get profile" do
    test "returns 200 and renders profile when follower is not authenticated", %{
      conn: conn,
      followed: followed
    } do
      get_profile_conn =
        conn
        |> get(Routes.profile_path(conn, :get_profile, followed.username))

      assert %{"profile" => profile} = json_response(get_profile_conn, 200)
      assert profile["username"] == followed.username
      assert profile["bio"] == followed.bio
      assert profile["image"] == followed.image
      assert !profile["following"]
    end

    test "returns 200 and renders profile when user is followed and follower is authenticated", %{
      conn: conn,
      follower: follower,
      followed: followed
    } do
      follow_user_conn =
        conn
        |> secure_conn(follower.id)
        |> post(Routes.profile_path(conn, :follow_user, followed.username))

      assert %{"profile" => profile} = json_response(follow_user_conn, 200)
      assert profile["username"] == followed.username
      assert profile["bio"] == followed.bio
      assert profile["image"] == followed.image
      assert profile["following"]

      get_profile_conn =
        conn
        |> secure_conn(follower.id)
        |> get(Routes.profile_path(conn, :get_profile, followed.username))

      assert %{"profile" => got_profile} = json_response(get_profile_conn, 200)
      assert profile == got_profile
    end

    test "returns 200 and renders profile when user is not followed and follower is authenticated",
         %{
           conn: conn,
           follower: follower,
           followed: followed
         } do
      get_profile_conn =
        conn
        |> secure_conn(follower.id)
        |> get(Routes.profile_path(conn, :get_profile, followed.username))

      assert %{"profile" => profile} = json_response(get_profile_conn, 200)
      assert profile["username"] == followed.username
      assert profile["bio"] == followed.bio
      assert profile["image"] == followed.image
      assert !profile["following"]
    end

    test "returns 200 and renders profile when follower is not found", %{
      conn: conn,
      followed: followed
    } do
      user_id = Faker.UUID.v4()

      get_profile_conn =
        conn
        |> secure_conn(user_id)
        |> get(Routes.profile_path(conn, :get_profile, followed.username))

      assert %{"profile" => profile} = json_response(get_profile_conn, 200)
      assert profile["username"] == followed.username
      assert profile["bio"] == followed.bio
      assert profile["image"] == followed.image
      assert !profile["following"]
    end

    test "returns 404 and renders errors when followed is not found", %{
      conn: conn
    } do
      followed_username = Faker.Internet.user_name()

      get_profile_conn =
        conn
        |> get(Routes.profile_path(conn, :get_profile, followed_username))

      assert json_response(get_profile_conn, 404)["errors"]["body"] == [
               "User #{followed_username} not found"
             ]
    end
  end

  describe "unfollow user" do
    test "returns 200 and renders profile when user is followed", %{
      conn: conn,
      follower: follower,
      followed: followed
    } do
      follow_user_conn =
        conn
        |> secure_conn(follower.id)
        |> post(Routes.profile_path(conn, :follow_user, followed.username))

      assert %{"profile" => _} = json_response(follow_user_conn, 200)

      unfollow_user_conn =
        conn
        |> secure_conn(follower.id)
        |> delete(Routes.profile_path(conn, :unfollow_user, followed.username))

      assert %{"profile" => profile} = json_response(unfollow_user_conn, 200)
      assert profile["username"] == followed.username
      assert profile["bio"] == followed.bio
      assert profile["image"] == followed.image
      assert !profile["following"]

      get_profile_conn =
        conn
        |> secure_conn(follower.id)
        |> get(Routes.profile_path(conn, :get_profile, followed.username))

      assert %{"profile" => found_profile} = json_response(get_profile_conn, 200)
      assert profile == found_profile
    end

    test "returns 200 and renders profile when user is not followed", %{
      conn: conn,
      follower: follower,
      followed: followed
    } do
      unfollow_user_conn =
        conn
        |> secure_conn(follower.id)
        |> delete(Routes.profile_path(conn, :unfollow_user, followed.username))

      assert %{"profile" => profile} = json_response(unfollow_user_conn, 200)
      assert profile["username"] == followed.username
      assert profile["bio"] == followed.bio
      assert profile["image"] == followed.image
      assert !profile["following"]

      get_profile_conn =
        conn
        |> secure_conn(follower.id)
        |> get(Routes.profile_path(conn, :get_profile, followed.username))

      assert %{"profile" => found_profile} = json_response(get_profile_conn, 200)
      assert profile == found_profile
    end

    test "returns 401 and renders errors when bearer token is not sent", %{
      conn: conn,
      followed: followed
    } do
      follow_user_conn =
        conn
        |> delete(Routes.profile_path(conn, :unfollow_user, followed.username))

      assert json_response(follow_user_conn, 401)["errors"]["body"] == [
               "Unauthorized"
             ]
    end

    test "returns 401 and renders errors when follower is not found", %{
      conn: conn,
      followed: followed
    } do
      user_id = Faker.UUID.v4()

      follow_user_conn =
        conn
        |> secure_conn(user_id)
        |> delete(Routes.profile_path(conn, :unfollow_user, followed.username))

      assert json_response(follow_user_conn, 401)["errors"]["body"] == [
               "Unauthorized"
             ]
    end

    test "returns 404 and renders errors when followed is not found", %{
      conn: conn,
      follower: follower
    } do
      followed_username = Faker.Internet.user_name()

      follow_user_conn =
        conn
        |> secure_conn(follower.id)
        |> delete(Routes.profile_path(conn, :unfollow_user, followed_username))

      assert json_response(follow_user_conn, 404)["errors"]["body"] == [
               "User #{followed_username} not found"
             ]
    end
  end
end
