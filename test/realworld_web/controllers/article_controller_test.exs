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
        tagList: Faker.Lorem.words()
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
      assert article["tagList"] == create_article_params.tagList
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

    test "returns 201 and renders article when tagList is not sent", %{
      conn: conn
    } do
      author = insert(:user)

      create_article_params = %{
        title: Faker.Lorem.sentence(),
        description: Faker.Lorem.sentence(),
        body: Faker.Lorem.paragraph()
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
      assert article["tagList"] == []
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
        tagList: Faker.Lorem.words()
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
        tagList: Faker.Lorem.words()
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

  describe "get article" do
    test "returns 200 and renders article when article is favorited and author is followed", %{
      conn: conn
    } do
      user1 = insert(:user)
      user2 = insert(:user)
      author = insert(:user)
      article = insert(:article, author: author)

      user2_favorite_article_conn =
        conn
        |> secure_conn(user2.id)
        |> post(Routes.article_path(conn, :favorite_article, article.slug))

      assert %{"article" => _} = json_response(user2_favorite_article_conn, 200)

      user1_favorite_article_conn =
        conn
        |> secure_conn(user1.id)
        |> post(Routes.article_path(conn, :favorite_article, article.slug))

      assert %{"article" => _} = json_response(user1_favorite_article_conn, 200)

      user1_follow_user_conn =
        conn
        |> secure_conn(user1.id)
        |> post(Routes.profile_path(conn, :follow_user, author.username))

      assert %{"profile" => _} = json_response(user1_follow_user_conn, 200)

      user1_get_article_conn =
        conn
        |> secure_conn(user1.id)
        |> get(Routes.article_path(conn, :get_article, article.slug))

      assert %{"article" => user1_article} = json_response(user1_get_article_conn, 200)
      assert user1_article["slug"] == Slug.slugify(article.title)
      assert user1_article["title"] == article.title
      assert user1_article["description"] == article.description
      assert user1_article["body"] == article.body
      assert user1_article["tagList"] == article.tags
      assert user1_article["createdAt"] == Date.to_iso8601(article.inserted_at)
      assert user1_article["updatedAt"] == Date.to_iso8601(article.updated_at)
      assert user1_article["favorited"]
      assert user1_article["favoritesCount"] == 2

      assert user1_article["author"] == %{
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

      user2_favorite_article_conn =
        conn
        |> secure_conn(user2.id)
        |> post(Routes.article_path(conn, :favorite_article, article.slug))

      assert %{"article" => _} = json_response(user2_favorite_article_conn, 200)

      user1_follow_user_conn =
        conn
        |> secure_conn(user1.id)
        |> post(Routes.profile_path(conn, :follow_user, author.username))

      assert %{"profile" => _} = json_response(user1_follow_user_conn, 200)

      user1_get_article_conn =
        conn
        |> secure_conn(user1.id)
        |> get(Routes.article_path(conn, :get_article, article.slug))

      assert %{"article" => user1_article} = json_response(user1_get_article_conn, 200)
      assert user1_article["slug"] == Slug.slugify(article.title)
      assert user1_article["title"] == article.title
      assert user1_article["description"] == article.description
      assert user1_article["body"] == article.body
      assert user1_article["tagList"] == article.tags
      assert {:ok, _} = Date.from_iso8601(user1_article["createdAt"])
      assert {:ok, _} = Date.from_iso8601(user1_article["updatedAt"])
      assert !user1_article["favorited"]
      assert user1_article["favoritesCount"] == 1

      assert user1_article["author"] == %{
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

      user2_favorite_article_conn =
        conn
        |> secure_conn(user2.id)
        |> post(Routes.article_path(conn, :favorite_article, article.slug))

      assert %{"article" => _} = json_response(user2_favorite_article_conn, 200)

      user1_get_article_conn =
        conn
        |> secure_conn(user1.id)
        |> get(Routes.article_path(conn, :get_article, article.slug))

      assert %{"article" => user1_article} = json_response(user1_get_article_conn, 200)
      assert user1_article["slug"] == Slug.slugify(article.title)
      assert user1_article["title"] == article.title
      assert user1_article["description"] == article.description
      assert user1_article["body"] == article.body
      assert user1_article["tagList"] == article.tags
      assert user1_article["createdAt"] != nil
      assert user1_article["updatedAt"] != nil
      assert !user1_article["favorited"]
      assert user1_article["favoritesCount"] == 1

      assert user1_article["author"] == %{
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

      user2_favorite_article_conn =
        conn
        |> secure_conn(user2.id)
        |> post(Routes.article_path(conn, :favorite_article, article.slug))

      assert %{"article" => _} = json_response(user2_favorite_article_conn, 200)

      user1_favorite_article_conn =
        conn
        |> secure_conn(user1.id)
        |> post(Routes.article_path(conn, :favorite_article, article.slug))

      assert %{"article" => _} = json_response(user1_favorite_article_conn, 200)

      user1_follow_user_conn =
        conn
        |> secure_conn(user1.id)
        |> post(Routes.profile_path(conn, :follow_user, author.username))

      assert %{"profile" => _} = json_response(user1_follow_user_conn, 200)

      get_article_conn =
        conn
        |> get(Routes.article_path(conn, :get_article, article.slug))

      assert %{"article" => got_article} = json_response(get_article_conn, 200)
      assert got_article["slug"] == Slug.slugify(article.title)
      assert got_article["title"] == article.title
      assert got_article["description"] == article.description
      assert got_article["body"] == article.body
      assert got_article["tagList"] == article.tags
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

  describe "list_articles" do
    test "returns 200 and renders empty list of articles no articles exist", %{
      conn: conn
    } do
      user = insert(:user)

      list_articles_conn =
        conn
        |> secure_conn(user.id)
        |> get(Routes.article_path(conn, :list_articles))

      assert %{"articles" => articles, "articlesCount" => articles_count} =
               json_response(list_articles_conn, 200)

      assert Enum.empty?(articles)
      assert articles_count == 0
    end

    test "returns 200 and renders multiple articles when given all filters", %{
      conn: conn
    } do
      user1 = insert(:user)
      user2 = insert(:user)
      user3 = insert(:user)
      tag1 = insert(:tag, name: "tag1")
      tag2 = insert(:tag, name: "tag2")

      limit = 3
      offset = 1

      article1 =
        insert(:article,
          author: user1,
          tags: [tag1],
          inserted_at: DateTime.utc_now() |> Timex.subtract(Timex.Duration.from_days(3))
        )

      article2 =
        insert(:article,
          author: user1,
          tags: [tag1, tag2],
          inserted_at: DateTime.utc_now() |> Timex.subtract(Timex.Duration.from_days(2))
        )

      article3 =
        insert(:article,
          author: user1,
          tags: [tag1],
          inserted_at: DateTime.utc_now() |> Timex.subtract(Timex.Duration.from_days(1))
        )

      article4 =
        insert(:article,
          author: user1,
          tags: [tag1]
        )

      Enum.each([article1, article2, article3, article4], fn article ->
        user2_favorite_article_conn =
          conn
          |> secure_conn(user2.id)
          |> post(Routes.article_path(conn, :favorite_article, article.slug))

        assert %{"article" => _} = json_response(user2_favorite_article_conn, 200)

        user3_favorite_article_conn =
          conn
          |> secure_conn(user3.id)
          |> post(Routes.article_path(conn, :favorite_article, article.slug))

        assert %{"article" => _} = json_response(user3_favorite_article_conn, 200)
      end)

      user2_follow_user1_conn =
        conn
        |> secure_conn(user2.id)
        |> post(Routes.profile_path(conn, :follow_user, user1.username))

      assert %{"profile" => _} = json_response(user2_follow_user1_conn, 200)

      list_articles_params = %{
        tag: tag1.name,
        author: user1.username,
        favorited: user2.username,
        limit: limit,
        offset: offset
      }

      expected_articles = [
        article3,
        article2,
        article1
      ]

      list_articles_conn =
        conn
        |> secure_conn(user2.id)
        |> get(Routes.article_path(conn, :list_articles, list_articles_params))

      assert %{"articles" => articles, "articlesCount" => articles_count} =
               json_response(list_articles_conn, 200)

      for i <- 0..(length(articles) - 1) do
        article = Enum.at(articles, i)
        expected_article = Enum.at(expected_articles, i)

        assert article["slug"] == Slug.slugify(expected_article.title)
        assert article["title"] == expected_article.title
        assert article["description"] == expected_article.description
        assert article["body"] == expected_article.body
        assert article["tagList"] == expected_article.tags |> Enum.map(& &1.name)
        assert article["createdAt"] == Date.to_iso8601(expected_article.inserted_at)
        assert article["updatedAt"] == Date.to_iso8601(expected_article.updated_at)
        assert article["favorited"]
        assert article["favoritesCount"] == 2

        assert article["author"] == %{
                 "username" => user1.username,
                 "bio" => user1.bio,
                 "image" => user1.image,
                 "following" => true
               }
      end

      assert articles_count == length(expected_articles)
    end

    test "returns 200 and renders 20 articles by default when limit is not set", %{
      conn: conn
    } do
      limit_by_default = 20

      for _ <- 0..(limit_by_default + 5) do
        insert(:article)
      end

      list_articles_conn =
        conn
        |> get(Routes.article_path(conn, :list_articles))

      assert %{"articles" => articles, "articlesCount" => articles_count} =
               json_response(list_articles_conn, 200)

      assert length(articles) == limit_by_default
      assert articles_count == limit_by_default
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
        tagList: Faker.Lorem.words()
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
      assert updated_article["tagList"] == update_article_params.tagList
      assert updated_article["createdAt"] == Date.to_iso8601(article.inserted_at)
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
        tagList: Faker.Lorem.words()
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
        tagList: Faker.Lorem.words()
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
        tagList: Faker.Lorem.words()
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

      user1_favorite_article_conn =
        conn
        |> secure_conn(user1.id)
        |> post(Routes.article_path(conn, :favorite_article, article.slug))

      assert %{"article" => user1_article} = json_response(user1_favorite_article_conn, 200)
      assert user1_article["slug"] == Slug.slugify(article.title)
      assert user1_article["title"] == article.title
      assert user1_article["description"] == article.description
      assert user1_article["body"] == article.body
      assert user1_article["tagList"] == article.tags
      assert user1_article["createdAt"] == Date.to_iso8601(article.inserted_at)
      assert user1_article["updatedAt"] == Date.to_iso8601(article.updated_at)
      assert user1_article["favorited"]
      assert user1_article["favoritesCount"] == 1

      assert user1_article["author"] == %{
               "username" => author.username,
               "bio" => author.bio,
               "image" => author.image,
               "following" => false
             }

      user2_favorite_article_conn =
        conn
        |> secure_conn(user2.id)
        |> post(Routes.article_path(conn, :favorite_article, article.slug))

      assert %{"article" => user2_article} = json_response(user2_favorite_article_conn, 200)

      assert Map.delete(user2_article, "favoritesCount") ==
               Map.delete(user1_article, "favoritesCount")

      assert user2_article["favoritesCount"] == 2
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

  describe "unfavorite article" do
    test "returns 200 and renders article", %{
      conn: conn
    } do
      user1 = insert(:user)
      user2 = insert(:user)
      author = insert(:user)
      article = insert(:article, author: author)

      user1_favorite_article_conn =
        conn
        |> secure_conn(user1.id)
        |> post(Routes.article_path(conn, :favorite_article, article.slug))

      assert %{"article" => _} = json_response(user1_favorite_article_conn, 200)

      user2_favorite_article_conn =
        conn
        |> secure_conn(user2.id)
        |> post(Routes.article_path(conn, :favorite_article, article.slug))

      assert %{"article" => _} = json_response(user2_favorite_article_conn, 200)

      user1_unfavorite_article_conn =
        conn
        |> secure_conn(user1.id)
        |> delete(Routes.article_path(conn, :unfavorite_article, article.slug))

      assert %{"article" => user1_article} = json_response(user1_unfavorite_article_conn, 200)
      assert user1_article["slug"] == Slug.slugify(article.title)
      assert user1_article["title"] == article.title
      assert user1_article["description"] == article.description
      assert user1_article["body"] == article.body
      assert user1_article["tagList"] == article.tags
      assert user1_article["createdAt"] == Date.to_iso8601(article.inserted_at)
      assert user1_article["updatedAt"] == Date.to_iso8601(article.updated_at)
      assert !user1_article["favorited"]
      assert user1_article["favoritesCount"] == 1

      assert user1_article["author"] == %{
               "username" => author.username,
               "bio" => author.bio,
               "image" => author.image,
               "following" => false
             }

      user2_unfavorite_article_conn =
        conn
        |> secure_conn(user2.id)
        |> delete(Routes.article_path(conn, :unfavorite_article, article.slug))

      assert %{"article" => user2_article} = json_response(user2_unfavorite_article_conn, 200)

      assert Map.delete(user2_article, "favoritesCount") ==
               Map.delete(user1_article, "favoritesCount")

      assert user2_article["favoritesCount"] == 0
    end

    test "returns 401 and renders errors when bearer token is not sent", %{
      conn: conn
    } do
      article = insert(:article)

      unfavorite_article_conn =
        conn
        |> delete(Routes.article_path(conn, :unfavorite_article, article.slug))

      assert json_response(unfavorite_article_conn, 401)["errors"]["body"] == [
               "Unauthorized"
             ]
    end

    test "returns 401 and renders errors when author is not found", %{
      conn: conn
    } do
      article = insert(:article)

      author_id = Faker.UUID.v4()

      unfavorite_article_conn =
        conn
        |> secure_conn(author_id)
        |> delete(Routes.article_path(conn, :unfavorite_article, article.slug))

      assert json_response(unfavorite_article_conn, 401)["errors"]["body"] == [
               "Unauthorized"
             ]
    end
  end
end
