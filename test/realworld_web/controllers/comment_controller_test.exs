defmodule RealWorldWeb.CommentControllerTest do
  use RealWorldWeb.ConnCase

  import RealWorld.Factory
  import RealWorld.TestUtils
  alias RealWorld.Articles.Article

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "add comment" do
    test "returns 201 and renders a comment", %{
      conn: conn
    } do
      user = insert(:user)
      article = insert(:article)

      create_comment_params = %{
        body: Faker.Lorem.sentence()
      }

      create_comment_conn =
        conn
        |> secure_conn(user.id)
        |> post(Routes.comment_path(conn, :add_comment, article.slug),
          comment: create_comment_params
        )

      assert %{"comment" => comment} = json_response(create_comment_conn, 201)
      assert comment["id"] != nil
      assert {:ok, _} = Date.from_iso8601(comment["createdAt"])
      assert {:ok, _} = Date.from_iso8601(comment["updatedAt"])
      assert comment["body"] == create_comment_params.body

      assert comment["author"] == %{
               "username" => user.username,
               "bio" => user.bio,
               "image" => user.image,
               "following" => false
             }

      get_article_comments_conn =
        conn
        |> secure_conn(user.id)
        |> get(Routes.comment_path(conn, :get_article_comments, article.slug))

      assert %{"comments" => comments} = json_response(get_article_comments_conn, 200)
      assert length(comments) == 1
      assert comment == Enum.at(comments, 0)
    end

    test "returns 401 and renders errors when bearer token is not sent", %{
      conn: conn
    } do
      article = insert(:article)

      create_comment_params = %{
        body: Faker.Lorem.sentence()
      }

      create_comment_conn =
        conn
        |> post(Routes.comment_path(conn, :add_comment, article.slug),
          comment: create_comment_params
        )

      assert json_response(create_comment_conn, 401)["errors"]["body"] == [
               "Unauthorized"
             ]
    end

    test "returns 401 and renders errors when author is not found", %{
      conn: conn
    } do
      user_id = Faker.UUID.v4()
      article = insert(:article)

      create_comment_params = %{
        body: Faker.Lorem.sentence()
      }

      create_comment_conn =
        conn
        |> secure_conn(user_id)
        |> post(Routes.comment_path(conn, :add_comment, article.slug),
          comment: create_comment_params
        )

      assert json_response(create_comment_conn, 401)["errors"]["body"] == [
               "Unauthorized"
             ]
    end

    test "returns 404 and renders errors when article is not found", %{
      conn: conn
    } do
      user = insert(:user)

      article = %Article{
        slug: Slug.slugify(Faker.Lorem.sentence())
      }

      create_comment_params = %{
        body: Faker.Lorem.sentence()
      }

      create_comment_conn =
        conn
        |> secure_conn(user.id)
        |> post(Routes.comment_path(conn, :add_comment, article.slug),
          comment: create_comment_params
        )

      assert json_response(create_comment_conn, 404)["errors"]["body"] == [
               "slug #{article.slug} not found"
             ]
    end
  end

  describe "get article comments" do
    test "returns 200 and renders multiple comments", %{
      conn: conn
    } do
      article = insert(:article)
      comment_author1 = insert(:user)
      comment_author2 = insert(:user)

      author1_follow_author2_conn =
        conn
        |> secure_conn(comment_author1.id)
        |> post(Routes.profile_path(conn, :follow_user, comment_author2.username))

      assert %{"profile" => _} = json_response(author1_follow_author2_conn, 200)

      author2_comment1 =
        insert(:comment,
          author: comment_author2,
          article: article,
          inserted_at: DateTime.utc_now() |> Timex.subtract(Timex.Duration.from_days(2))
        )

      author1_comment1 =
        insert(:comment,
          author: comment_author1,
          article: article,
          inserted_at: DateTime.utc_now() |> Timex.subtract(Timex.Duration.from_days(1))
        )

      author2_comment2 = insert(:comment, author: comment_author2, article: article)

      expected_comments = [author2_comment2, author1_comment1, author2_comment1]

      get_article_comments_conn =
        conn
        |> secure_conn(comment_author1.id)
        |> get(Routes.comment_path(conn, :get_article_comments, article.slug))

      assert %{"comments" => comments} = json_response(get_article_comments_conn, 200)
      assert length(comments) == 3

      comment0 = Enum.at(comments, 0)
      expected_comment0 = Enum.at(expected_comments, 0)

      assert comment0["id"] == expected_comment0.id
      assert comment0["createdAt"] == Date.to_iso8601(expected_comment0.inserted_at)
      assert comment0["updatedAt"] == Date.to_iso8601(expected_comment0.updated_at)
      assert comment0["body"] == expected_comment0.body

      assert comment0["author"] == %{
               "username" => comment_author2.username,
               "bio" => comment_author2.bio,
               "image" => comment_author2.image,
               "following" => true
             }

      comment1 = Enum.at(comments, 1)
      expected_comment1 = Enum.at(expected_comments, 1)

      assert comment1["id"] == expected_comment1.id
      assert comment1["createdAt"] == Date.to_iso8601(expected_comment1.inserted_at)
      assert comment1["updatedAt"] == Date.to_iso8601(expected_comment1.updated_at)
      assert comment1["body"] == expected_comment1.body

      assert comment1["author"] == %{
               "username" => comment_author1.username,
               "bio" => comment_author1.bio,
               "image" => comment_author1.image,
               "following" => false
             }

      comment2 = Enum.at(comments, 2)
      expected_comment2 = Enum.at(expected_comments, 2)

      assert comment2["id"] == expected_comment2.id
      assert comment2["createdAt"] == Date.to_iso8601(expected_comment2.inserted_at)
      assert comment2["updatedAt"] == Date.to_iso8601(expected_comment2.updated_at)
      assert comment2["body"] == expected_comment2.body

      assert comment2["author"] == %{
               "username" => comment_author2.username,
               "bio" => comment_author2.bio,
               "image" => comment_author2.image,
               "following" => true
             }
    end

    test "returns 200 and renders multiple comments when no bearer token is sent", %{
      conn: conn
    } do
      article = insert(:article)
      comment_author1 = insert(:user)
      comment_author2 = insert(:user)

      author1_follow_author2_conn =
        conn
        |> secure_conn(comment_author1.id)
        |> post(Routes.profile_path(conn, :follow_user, comment_author2.username))

      assert %{"profile" => _} = json_response(author1_follow_author2_conn, 200)

      author2_comment1 =
        insert(:comment,
          author: comment_author2,
          article: article,
          inserted_at: DateTime.utc_now() |> Timex.subtract(Timex.Duration.from_days(2))
        )

      author1_comment1 =
        insert(:comment,
          author: comment_author1,
          article: article,
          inserted_at: DateTime.utc_now() |> Timex.subtract(Timex.Duration.from_days(1))
        )

      author2_comment2 = insert(:comment, author: comment_author2, article: article)

      expected_comments = [author2_comment2, author1_comment1, author2_comment1]

      get_article_comments_conn =
        conn
        |> get(Routes.comment_path(conn, :get_article_comments, article.slug))

      assert %{"comments" => comments} = json_response(get_article_comments_conn, 200)
      assert length(comments) == 3

      comment0 = Enum.at(comments, 0)
      expected_comment0 = Enum.at(expected_comments, 0)

      assert comment0["id"] == expected_comment0.id
      assert comment0["createdAt"] == Date.to_iso8601(expected_comment0.inserted_at)
      assert comment0["updatedAt"] == Date.to_iso8601(expected_comment0.updated_at)
      assert comment0["body"] == expected_comment0.body

      assert comment0["author"] == %{
               "username" => comment_author2.username,
               "bio" => comment_author2.bio,
               "image" => comment_author2.image,
               "following" => false
             }

      comment1 = Enum.at(comments, 1)
      expected_comment1 = Enum.at(expected_comments, 1)

      assert comment1["id"] == expected_comment1.id
      assert comment1["createdAt"] == Date.to_iso8601(expected_comment1.inserted_at)
      assert comment1["updatedAt"] == Date.to_iso8601(expected_comment1.updated_at)
      assert comment1["body"] == expected_comment1.body

      assert comment1["author"] == %{
               "username" => comment_author1.username,
               "bio" => comment_author1.bio,
               "image" => comment_author1.image,
               "following" => false
             }

      comment2 = Enum.at(comments, 2)
      expected_comment2 = Enum.at(expected_comments, 2)

      assert comment2["id"] == expected_comment2.id
      assert comment2["createdAt"] == Date.to_iso8601(expected_comment2.inserted_at)
      assert comment2["updatedAt"] == Date.to_iso8601(expected_comment2.updated_at)
      assert comment2["body"] == expected_comment2.body

      assert comment2["author"] == %{
               "username" => comment_author2.username,
               "bio" => comment_author2.bio,
               "image" => comment_author2.image,
               "following" => false
             }
    end

    test "returns 401 and renders errors when bearer token is set and author is not found", %{
      conn: conn
    } do
      user_id = Faker.UUID.v4()
      article = insert(:article)

      create_comment_params = %{
        body: Faker.Lorem.sentence()
      }

      create_comment_conn =
        conn
        |> secure_conn(user_id)
        |> post(Routes.comment_path(conn, :add_comment, article.slug),
          comment: create_comment_params
        )

      assert json_response(create_comment_conn, 401)["errors"]["body"] == [
               "Unauthorized"
             ]
    end

    test "returns 404 and renders errors when article is not found", %{
      conn: conn
    } do
      user = insert(:user)

      article = %Article{
        slug: Slug.slugify(Faker.Lorem.sentence())
      }

      create_comment_conn =
        conn
        |> secure_conn(user.id)
        |> get(Routes.comment_path(conn, :get_article_comments, article.slug))

      assert json_response(create_comment_conn, 404)["errors"]["body"] == [
               "slug #{article.slug} not found"
             ]
    end
  end
end
