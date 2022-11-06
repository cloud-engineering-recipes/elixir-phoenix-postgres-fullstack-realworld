defmodule RealWorldWeb.ArticleControllerTest do
  use RealWorldWeb.ConnCase

  import RealWorld.Factory
  import RealWorld.TestUtils

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "create article" do
    test "returns 201 and renders article", %{
      conn: conn
    } do
      author = insert(:user)

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
      assert {:ok, _} = Date.from_iso8601(article["createdAt"])
      assert {:ok, _} = Date.from_iso8601(article["updatedAt"])
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

  describe "update article" do
    test "returns 200 and renders article", %{
      conn: conn
    } do
      author = insert(:user)
      article = insert(:article, author: author)

      update_article_params = %{
        title: Faker.Lorem.sentence(),
        description: Faker.Lorem.sentence(),
        body: Faker.Lorem.paragraph(),
        tag_list: Faker.Lorem.words()
      }

      update_article_conn =
        conn
        |> secure_conn(author.id)
        |> put(Routes.article_path(conn, :update_article, article.slug),
          article: update_article_params
        )

      assert %{"article" => updated_article} = json_response(update_article_conn, 200)
      assert updated_article["slug"] == Slug.slugify(update_article_params.title)
      assert updated_article["title"] == update_article_params.title
      assert updated_article["description"] == update_article_params.description
      assert updated_article["body"] == update_article_params.body
      assert updated_article["tagList"] == update_article_params.tag_list
      assert {:ok, _} = Date.from_iso8601(updated_article["createdAt"])
      assert {:ok, _} = Date.from_iso8601(updated_article["updatedAt"])
      assert !updated_article["favorited"]
      assert updated_article["favoritesCount"] == 0

      assert updated_article["author"] == %{
               "username" => author.username,
               "bio" => author.bio,
               "image" => author.image,
               "following" => false
             }

      get_article_conn =
        conn
        |> secure_conn(author.id)
        |> get(Routes.article_path(conn, :get_article, updated_article["slug"]))

      assert %{"article" => got_article} = json_response(get_article_conn, 200)
      assert updated_article == got_article
    end

    test "returns 401 and renders errors when the token does not belong to the author", %{
      conn: conn
    } do
      another_user = insert(:user)
      article = insert(:article)

      update_article_params = %{
        title: Faker.Lorem.sentence(),
        description: Faker.Lorem.sentence(),
        body: Faker.Lorem.paragraph(),
        tag_list: Faker.Lorem.words()
      }

      update_article_conn =
        conn
        |> secure_conn(another_user.id)
        |> put(Routes.article_path(conn, :update_article, article.slug),
          article: update_article_params
        )

      assert json_response(update_article_conn, 401)["errors"]["body"] == [
               "Unauthorized"
             ]
    end

    test "returns 401 and renders errors when bearer token is not sent", %{
      conn: conn
    } do
      article = insert(:article)

      update_article_params = %{
        title: Faker.Lorem.sentence(),
        description: Faker.Lorem.sentence(),
        body: Faker.Lorem.paragraph(),
        tag_list: Faker.Lorem.words()
      }

      update_article_conn =
        conn
        |> put(Routes.article_path(conn, :update_article, article.slug),
          article: update_article_params
        )

      assert json_response(update_article_conn, 401)["errors"]["body"] == [
               "Unauthorized"
             ]
    end

    test "returns 401 and renders errors when author is not found", %{
      conn: conn
    } do
      article = insert(:article)

      author_id = Faker.UUID.v4()

      update_article_params = %{
        title: Faker.Lorem.sentence(),
        description: Faker.Lorem.sentence(),
        body: Faker.Lorem.paragraph(),
        tag_list: Faker.Lorem.words()
      }

      update_article_conn =
        conn
        |> secure_conn(author_id)
        |> put(Routes.article_path(conn, :update_article, article.slug),
          article: update_article_params
        )

      assert json_response(update_article_conn, 401)["errors"]["body"] == [
               "Unauthorized"
             ]
    end
  end

  describe "favorite article" do
    test "returns 200 and renders article", %{
      conn: conn
    } do
      user1 = insert(:user)
      user2 = insert(:user)
      author = insert(:user)
      article = insert(:article, author: author)

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
               "username" => author.username,
               "bio" => author.bio,
               "image" => author.image,
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
      conn: conn
    } do
      article = insert(:article)

      favorite_article_conn =
        conn
        |> post(Routes.article_path(conn, :favorite_article, article.slug))

      assert json_response(favorite_article_conn, 401)["errors"]["body"] == [
               "Unauthorized"
             ]
    end

    test "returns 401 and renders errors when author is not found", %{
      conn: conn
    } do
      article = insert(:article)

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
      conn: conn
    } do
      user1 = insert(:user)
      user2 = insert(:user)
      author = insert(:user)
      article = insert(:article, author: author)

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
        |> post(Routes.profile_path(conn, :follow_user, author.username))

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
               "username" => author.username,
               "bio" => author.bio,
               "image" => author.image,
               "following" => true
             }
    end

    test "returns 200 and renders article when article is not favorited and author is followed",
         %{
           conn: conn
         } do
      user1 = insert(:user)
      user2 = insert(:user)
      author = insert(:user)
      article = insert(:article, author: author)

      user_2_favorite_article_conn =
        conn
        |> secure_conn(user2.id)
        |> post(Routes.article_path(conn, :favorite_article, article.slug))

      assert %{"article" => _} = json_response(user_2_favorite_article_conn, 200)

      user_1_follow_user_conn =
        conn
        |> secure_conn(user1.id)
        |> post(Routes.profile_path(conn, :follow_user, author.username))

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
               "username" => author.username,
               "bio" => author.bio,
               "image" => author.image,
               "following" => true
             }
    end

    test "returns 200 and renders article when article is not favorited and author is not followed",
         %{
           conn: conn
         } do
      user1 = insert(:user)
      user2 = insert(:user)
      author = insert(:user)
      article = insert(:article, author: author)

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
               "username" => author.username,
               "bio" => author.bio,
               "image" => author.image,
               "following" => false
             }
    end

    test "returns 200 and renders article when user is not authenticated", %{
      conn: conn
    } do
      user1 = insert(:user)
      user2 = insert(:user)
      author = insert(:user)
      article = insert(:article, author: author)

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
        |> post(Routes.profile_path(conn, :follow_user, author.username))

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
               "username" => author.username,
               "bio" => author.bio,
               "image" => author.image,
               "following" => false
             }
    end
  end
end
