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
      assert comment["createdAt"] == Date.to_iso8601(article.inserted_at)
      assert comment["updatedAt"] == Date.to_iso8601(article.updated_at)
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
end
