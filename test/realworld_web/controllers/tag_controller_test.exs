defmodule RealWorldWeb.TagControllerTest do
  use RealWorldWeb.ConnCase

  import RealWorld.Factory
  import RealWorld.TestUtils

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "get tags" do
    test "returns 200 and renders mutilple tags", %{
      conn: conn
    } do
      author = insert(:user)

      create_article1_params = %{
        title: Faker.Lorem.sentence(),
        description: Faker.Lorem.sentence(),
        body: Faker.Lorem.paragraph(),
        tagList: [
          "ctag"
        ]
      }

      create_article2_params = %{
        title: Faker.Lorem.sentence(),
        description: Faker.Lorem.sentence(),
        body: Faker.Lorem.paragraph(),
        tagList: [
          "ctag",
          "atag",
          "btag"
        ]
      }

      create_article1_conn =
        conn
        |> secure_conn(author.id)
        |> post(Routes.article_path(conn, :create_article), article: create_article1_params)

      assert %{"article" => _} = json_response(create_article1_conn, 201)

      create_article2_conn =
        conn
        |> secure_conn(author.id)
        |> post(Routes.article_path(conn, :create_article), article: create_article2_params)

      assert %{"article" => _} = json_response(create_article2_conn, 201)

      list_tags_conn =
        conn
        |> get(Routes.tag_path(conn, :get_tags))

      assert %{"tags" => tags} = json_response(list_tags_conn, 200)
      assert tags == ["atag", "btag", "ctag"]
    end

    test "returns 200 and renders empty list no tags exist", %{
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

      assert %{"article" => _} = json_response(create_article_conn, 201)

      list_tags_conn =
        conn
        |> get(Routes.tag_path(conn, :get_tags))

      assert %{"tags" => tags} = json_response(list_tags_conn, 200)
      assert tags == []
    end
  end
end
