defmodule RealWorldWeb.ArticleControllerTest do
  use RealWorldWeb.ConnCase

  import RealWorld.Factory
  import RealWorld.TestUtils

  setup %{conn: conn} do
    {:ok,
     conn: put_req_header(conn, "accept", "application/json"),
     user1: insert(:user),
     user2: insert(:user),
     article: insert(:article)}
  end

  describe "create article" do
    test "returns 201 and renders article", %{
      conn: conn,
      user1: author
    } do
      create_article_params = %{
        title: Faker.Lorem.sentence(),
        description: Faker.Lorem.sentence(),
        body: Faker.Lorem.paragraph(),
        tag_list: Faker.Lorem.words()
      }

      create_article_conn =
        conn
        |> secure_conn(author.id)
        |> post(Routes.article_path(conn, :create_article), article: create_article_params)

      assert %{"article" => article} = json_response(create_article_conn, 201)
      assert article["slug"] == Slug.slugify(create_article_params.title)
      assert article["title"] == create_article_params.title
      assert article["description"] == create_article_params.description
      assert article["body"] == create_article_params.body
      assert article["tagList"] == create_article_params.tag_list
      assert article["createdAt"] != nil
      assert article["updatedAt"] != nil
      assert !article["favorited"]
      assert article["favoritesCount"] == 0

      assert article["author"] == %{
               "username" => author.username,
               "bio" => author.bio,
               "image" => author.image,
               "following" => false
             }
    end

    test "returns 401 and renders errors when bearer token is not sent", %{
      conn: conn
    } do
      create_article_params = %{
        title: Faker.Lorem.sentence(),
        description: Faker.Lorem.sentence(),
        body: Faker.Lorem.paragraph(),
        tag_list: Faker.Lorem.words()
      }

      create_article_conn =
        conn
        |> post(Routes.article_path(conn, :create_article), article: create_article_params)

      assert json_response(create_article_conn, 401)["errors"]["body"] == [
               "Unauthorized"
             ]
    end

    test "returns 401 and renders errors when author is not found", %{
      conn: conn
    } do
      author_id = Faker.UUID.v4()

      create_article_params = %{
        title: Faker.Lorem.sentence(),
        description: Faker.Lorem.sentence(),
        body: Faker.Lorem.paragraph(),
        tag_list: Faker.Lorem.words()
      }

      create_article_conn =
        conn
        |> secure_conn(author_id)
        |> post(Routes.article_path(conn, :create_article), article: create_article_params)

      assert json_response(create_article_conn, 401)["errors"]["body"] == [
               "Unauthorized"
             ]
    end
  end

  describe "favorite article" do
    test "returns 200 and renders article", %{
      conn: conn,
      user1: user1,
      user2: user2,
      article: article
    } do
      user_1_favorite_article_conn =
        conn
        |> secure_conn(user1.id)
        |> post(Routes.article_path(conn, :favorite_article, article.slug))

      assert %{"article" => user_1_article} = json_response(user_1_favorite_article_conn, 200)
      assert user_1_article["slug"] == Slug.slugify(article.title)
      assert user_1_article["title"] == article.title
      assert user_1_article["description"] == article.description
      assert user_1_article["body"] == article.body
      assert user_1_article["tagList"] == article.tag_list
      assert user_1_article["createdAt"] != nil
      assert user_1_article["updatedAt"] != nil
      assert user_1_article["favorited"]
      assert user_1_article["favoritesCount"] == 1

      assert user_1_article["author"] == %{
               "username" => article.author.username,
               "bio" => article.author.bio,
               "image" => article.author.image,
               "following" => false
             }

      user_2_favorite_article_conn =
        conn
        |> secure_conn(user2.id)
        |> post(Routes.article_path(conn, :favorite_article, article.slug))

      assert %{"article" => user_2_article} = json_response(user_2_favorite_article_conn, 200)

      assert Map.delete(user_2_article, "favoritesCount") ==
               Map.delete(user_1_article, "favoritesCount")

      assert user_2_article["favoritesCount"] == 2
    end

    test "returns 401 and renders errors when bearer token is not sent", %{
      conn: conn,
      article: article
    } do
      favorite_article_conn =
        conn
        |> post(Routes.article_path(conn, :favorite_article, article.slug))

      assert json_response(favorite_article_conn, 401)["errors"]["body"] == [
               "Unauthorized"
             ]
    end

    test "returns 401 and renders errors when author is not found", %{
      conn: conn,
      article: article
    } do
      author_id = Faker.UUID.v4()

      favorite_article_conn =
        conn
        |> secure_conn(author_id)
        |> post(Routes.article_path(conn, :favorite_article, article.slug))

      assert json_response(favorite_article_conn, 401)["errors"]["body"] == [
               "Unauthorized"
             ]
    end
  end

  describe "get article" do
    test "returns 200 and renders article when article is favorited and author is followed", %{
      conn: conn,
      user1: user1,
      user2: user2,
      article: article
    } do
      user_2_favorite_article_conn =
        conn
        |> secure_conn(user2.id)
        |> post(Routes.article_path(conn, :favorite_article, article.slug))

      assert %{"article" => _} = json_response(user_2_favorite_article_conn, 200)

      user_1_favorite_article_conn =
        conn
        |> secure_conn(user1.id)
        |> post(Routes.article_path(conn, :favorite_article, article.slug))

      assert %{"article" => _} = json_response(user_1_favorite_article_conn, 200)

      user_1_follow_user_conn =
        conn
        |> secure_conn(user1.id)
        |> post(Routes.profile_path(conn, :follow_user, article.author.username))

      assert %{"profile" => _} = json_response(user_1_follow_user_conn, 200)

      user_1_get_article_conn =
        conn
        |> secure_conn(user1.id)
        |> get(Routes.article_path(conn, :get_article, article.slug))

      assert %{"article" => user_1_article} = json_response(user_1_get_article_conn, 200)
      assert user_1_article["slug"] == Slug.slugify(article.title)
      assert user_1_article["title"] == article.title
      assert user_1_article["description"] == article.description
      assert user_1_article["body"] == article.body
      assert user_1_article["tagList"] == article.tag_list
      assert user_1_article["createdAt"] != nil
      assert user_1_article["updatedAt"] != nil
      assert user_1_article["favorited"]
      assert user_1_article["favoritesCount"] == 2

      assert user_1_article["author"] == %{
               "username" => article.author.username,
               "bio" => article.author.bio,
               "image" => article.author.image,
               "following" => true
             }
    end

    test "returns 200 and renders article when article is not favorited and author is followed",
         %{
           conn: conn,
           user1: user1,
           user2: user2,
           article: article
         } do
      user_2_favorite_article_conn =
        conn
        |> secure_conn(user2.id)
        |> post(Routes.article_path(conn, :favorite_article, article.slug))

      assert %{"article" => _} = json_response(user_2_favorite_article_conn, 200)

      user_1_follow_user_conn =
        conn
        |> secure_conn(user1.id)
        |> post(Routes.profile_path(conn, :follow_user, article.author.username))

      assert %{"profile" => _} = json_response(user_1_follow_user_conn, 200)

      user_1_get_article_conn =
        conn
        |> secure_conn(user1.id)
        |> get(Routes.article_path(conn, :get_article, article.slug))

      assert %{"article" => user_1_article} = json_response(user_1_get_article_conn, 200)
      assert user_1_article["slug"] == Slug.slugify(article.title)
      assert user_1_article["title"] == article.title
      assert user_1_article["description"] == article.description
      assert user_1_article["body"] == article.body
      assert user_1_article["tagList"] == article.tag_list
      assert user_1_article["createdAt"] != nil
      assert user_1_article["updatedAt"] != nil
      assert !user_1_article["favorited"]
      assert user_1_article["favoritesCount"] == 1

      assert user_1_article["author"] == %{
               "username" => article.author.username,
               "bio" => article.author.bio,
               "image" => article.author.image,
               "following" => true
             }
    end

    test "returns 200 and renders article when article is not favorited and author is not followed",
         %{
           conn: conn,
           user1: user1,
           user2: user2,
           article: article
         } do
      user_2_favorite_article_conn =
        conn
        |> secure_conn(user2.id)
        |> post(Routes.article_path(conn, :favorite_article, article.slug))

      assert %{"article" => _} = json_response(user_2_favorite_article_conn, 200)

      user_1_get_article_conn =
        conn
        |> secure_conn(user1.id)
        |> get(Routes.article_path(conn, :get_article, article.slug))

      assert %{"article" => user_1_article} = json_response(user_1_get_article_conn, 200)
      assert user_1_article["slug"] == Slug.slugify(article.title)
      assert user_1_article["title"] == article.title
      assert user_1_article["description"] == article.description
      assert user_1_article["body"] == article.body
      assert user_1_article["tagList"] == article.tag_list
      assert user_1_article["createdAt"] != nil
      assert user_1_article["updatedAt"] != nil
      assert !user_1_article["favorited"]
      assert user_1_article["favoritesCount"] == 1

      assert user_1_article["author"] == %{
               "username" => article.author.username,
               "bio" => article.author.bio,
               "image" => article.author.image,
               "following" => false
             }
    end

    test "returns 200 and renders article when user is not authenticated", %{
      conn: conn,
      user1: user1,
      user2: user2,
      article: article
    } do
      user_2_favorite_article_conn =
        conn
        |> secure_conn(user2.id)
        |> post(Routes.article_path(conn, :favorite_article, article.slug))

      assert %{"article" => _} = json_response(user_2_favorite_article_conn, 200)

      user_1_favorite_article_conn =
        conn
        |> secure_conn(user1.id)
        |> post(Routes.article_path(conn, :favorite_article, article.slug))

      assert %{"article" => _} = json_response(user_1_favorite_article_conn, 200)

      user_1_follow_user_conn =
        conn
        |> secure_conn(user1.id)
        |> post(Routes.profile_path(conn, :follow_user, article.author.username))

      assert %{"profile" => _} = json_response(user_1_follow_user_conn, 200)

      get_article_conn =
        conn
        |> get(Routes.article_path(conn, :get_article, article.slug))

      assert %{"article" => got_article} = json_response(get_article_conn, 200)
      assert got_article["slug"] == Slug.slugify(article.title)
      assert got_article["title"] == article.title
      assert got_article["description"] == article.description
      assert got_article["body"] == article.body
      assert got_article["tagList"] == article.tag_list
      assert got_article["createdAt"] != nil
      assert got_article["updatedAt"] != nil
      assert !got_article["favorited"]
      assert got_article["favoritesCount"] == 2

      assert got_article["author"] == %{
               "username" => article.author.username,
               "bio" => article.author.bio,
               "image" => article.author.image,
               "following" => false
             }
    end

    #   test "returns 200 and renders profile when user is followed and follower is authenticated", %{
    #     conn: conn,
    #     follower: follower,
    #     followed: followed
    #   } do
    #     follow_user_conn =
    #       conn
    #       |> secure_conn(follower.id)
    #       |> post(Routes.profile_path(conn, :follow_user, followed.username))

    #     assert %{"profile" => profile} = json_response(follow_user_conn, 200)
    #     assert profile["username"] == followed.username
    #     assert profile["bio"] == followed.bio
    #     assert profile["image"] == followed.image
    #     assert profile["following"]

    #     get_profile_conn =
    #       conn
    #       |> secure_conn(follower.id)
    #       |> get(Routes.profile_path(conn, :get_profile, followed.username))

    #     assert %{"profile" => got_profile} = json_response(get_profile_conn, 200)
    #     assert profile == got_profile
    #   end

    #   test "returns 200 and renders profile when user is not followed and follower is authenticated",
    #        %{
    #          conn: conn,
    #          follower: follower,
    #          followed: followed
    #        } do
    #     get_profile_conn =
    #       conn
    #       |> secure_conn(follower.id)
    #       |> get(Routes.profile_path(conn, :get_profile, followed.username))

    #     assert %{"profile" => profile} = json_response(get_profile_conn, 200)
    #     assert profile["username"] == followed.username
    #     assert profile["bio"] == followed.bio
    #     assert profile["image"] == followed.image
    #     assert !profile["following"]
    #   end

    #   test "returns 200 and renders profile when follower is not found", %{
    #     conn: conn,
    #     followed: followed
    #   } do
    #     user_id = Faker.UUID.v4()

    #     get_profile_conn =
    #       conn
    #       |> secure_conn(user_id)
    #       |> get(Routes.profile_path(conn, :get_profile, followed.username))

    #     assert %{"profile" => profile} = json_response(get_profile_conn, 200)
    #     assert profile["username"] == followed.username
    #     assert profile["bio"] == followed.bio
    #     assert profile["image"] == followed.image
    #     assert !profile["following"]
    #   end

    #   test "returns 404 and renders errors when followed is not found", %{
    #     conn: conn
    #   } do
    #     followed_username = Faker.Internet.user_name()

    #     get_profile_conn =
    #       conn
    #       |> get(Routes.profile_path(conn, :get_profile, followed_username))

    #     assert json_response(get_profile_conn, 404)["errors"]["body"] == [
    #              "Username #{followed_username} not found"
    #            ]
    #   end
    # end

    # describe "unfollow user" do
    #   test "returns 200 and renders profile when user is followed", %{
    #     conn: conn,
    #     follower: follower,
    #     followed: followed
    #   } do
    #     follow_user_conn =
    #       conn
    #       |> secure_conn(follower.id)
    #       |> post(Routes.profile_path(conn, :follow_user, followed.username))

    #     assert %{"profile" => _} = json_response(follow_user_conn, 200)

    #     unfollow_user_conn =
    #       conn
    #       |> secure_conn(follower.id)
    #       |> delete(Routes.profile_path(conn, :unfollow_user, followed.username))

    #     assert %{"profile" => profile} = json_response(unfollow_user_conn, 200)
    #     assert profile["username"] == followed.username
    #     assert profile["bio"] == followed.bio
    #     assert profile["image"] == followed.image
    #     assert !profile["following"]

    #     get_profile_conn =
    #       conn
    #       |> secure_conn(follower.id)
    #       |> get(Routes.profile_path(conn, :get_profile, followed.username))

    #     assert %{"profile" => found_profile} = json_response(get_profile_conn, 200)
    #     assert profile == found_profile
    #   end

    #   test "returns 200 and renders profile when user is not followed", %{
    #     conn: conn,
    #     follower: follower,
    #     followed: followed
    #   } do
    #     unfollow_user_conn =
    #       conn
    #       |> secure_conn(follower.id)
    #       |> delete(Routes.profile_path(conn, :unfollow_user, followed.username))

    #     assert %{"profile" => profile} = json_response(unfollow_user_conn, 200)
    #     assert profile["username"] == followed.username
    #     assert profile["bio"] == followed.bio
    #     assert profile["image"] == followed.image
    #     assert !profile["following"]

    #     get_profile_conn =
    #       conn
    #       |> secure_conn(follower.id)
    #       |> get(Routes.profile_path(conn, :get_profile, followed.username))

    #     assert %{"profile" => found_profile} = json_response(get_profile_conn, 200)
    #     assert profile == found_profile
    #   end

    #   test "returns 401 and renders errors when bearer token is not sent", %{
    #     conn: conn,
    #     followed: followed
    #   } do
    #     follow_user_conn =
    #       conn
    #       |> delete(Routes.profile_path(conn, :unfollow_user, followed.username))

    #     assert json_response(follow_user_conn, 401)["errors"]["body"] == [
    #              "Unauthorized"
    #            ]
    #   end

    #   test "returns 401 and renders errors when follower is not found", %{
    #     conn: conn,
    #     followed: followed
    #   } do
    #     user_id = Faker.UUID.v4()

    #     follow_user_conn =
    #       conn
    #       |> secure_conn(user_id)
    #       |> delete(Routes.profile_path(conn, :unfollow_user, followed.username))

    #     assert json_response(follow_user_conn, 401)["errors"]["body"] == [
    #              "Unauthorized"
    #            ]
    #   end

    #   test "returns 404 and renders errors when followed is not found", %{
    #     conn: conn,
    #     follower: follower
    #   } do
    #     followed_username = Faker.Internet.user_name()

    #     follow_user_conn =
    #       conn
    #       |> secure_conn(follower.id)
    #       |> delete(Routes.profile_path(conn, :unfollow_user, followed_username))

    #     assert json_response(follow_user_conn, 404)["errors"]["body"] == [
    #              "Username #{followed_username} not found"
    #            ]
    #   end
  end
end
