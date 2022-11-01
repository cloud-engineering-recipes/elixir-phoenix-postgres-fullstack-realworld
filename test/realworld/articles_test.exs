defmodule RealWorld.ArticlesTest do
  use RealWorld.DataCase, async: true

  import RealWorld.Factory
  alias RealWorld.{Articles, Articles.Article}

  setup do
    {:ok, author: insert(:user), article: insert(:article)}
  end

  describe "create_article/1" do
    test "returns an article", %{author: author} do
      create_attrs = %{
        author_id: author.id,
        title: " My Awesome Article! It is really good! ",
        description: Faker.Lorem.sentence(),
        body: Faker.Lorem.paragraph(),
        tag_list: [
          nil,
          "",
          " ",
          "lower1",
          " lower2 ",
          "UPPER1",
          " UPPER2 ",
          "mIxEd1",
          " mIxEd2 ",
          " mIxEd3 ! "
        ]
      }

      assert {:ok, %Article{} = article} = Articles.create_article(create_attrs)

      assert article.author_id == create_attrs.author_id
      assert article.slug == "my-awesome-article-it-is-really-good"
      assert article.title == create_attrs.title
      assert article.description == create_attrs.description
      assert article.body == create_attrs.body

      assert article.tag_list == [
               "lower1",
               "lower2",
               "upper1",
               "upper2",
               "mixed1",
               "mixed2",
               "mixed3"
             ]

      with {:ok, %Article{} = got_article} <- Articles.get_article_by_id(article.id) do
        assert article == got_article
      end
    end

    test "returns :not_found when the author is not found" do
      create_attrs = %{
        author_id: Faker.UUID.v4(),
        title: Faker.Lorem.sentence(),
        description: Faker.Lorem.sentence(),
        body: Faker.Lorem.paragraph(),
        tag_list: Faker.Lorem.words()
      }

      assert {:not_found, "User #{create_attrs.author_id} not found"} ==
               Articles.create_article(create_attrs)
    end
  end

  describe "get_article_by_id/1" do
    test "returns the article", %{article: article} do
      assert {:ok, %Article{} = got_article} = Articles.get_article_by_id(article.id)
      assert Map.delete(got_article, :author) == Map.delete(article, :author)
    end

    test "returns :not_found when the article is not found" do
      article_id = Faker.UUID.v4()

      assert {:not_found, "Article #{article_id} not found"} ==
               Articles.get_article_by_id(article_id)
    end
  end
end
