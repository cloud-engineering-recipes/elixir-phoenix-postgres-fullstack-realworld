defmodule RealWorld.ArticlesTest do
  use RealWorld.DataCase, async: true

  import RealWorld.Factory
  import RealWorld.TestUtils
  alias RealWorld.{Articles, Articles.Article}

  setup do
    {:ok, user1: insert(:user), user2: insert(:user), article: insert(:article)}
  end

  describe "create_article/1" do
    test "returns an article", %{user1: author} do
      create_article_attrs = %{
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

      assert {:ok, %Article{} = article} = Articles.create_article(create_article_attrs)

      assert article.author_id == create_article_attrs.author_id
      assert article.slug == "my-awesome-article-it-is-really-good"
      assert article.title == create_article_attrs.title
      assert article.description == create_article_attrs.description
      assert article.body == create_article_attrs.body

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
      create_article_attrs = %{
        author_id: Faker.UUID.v4(),
        title: Faker.Lorem.sentence(),
        description: Faker.Lorem.sentence(),
        body: Faker.Lorem.paragraph(),
        tag_list: Faker.Lorem.words()
      }

      assert {:not_found, "User #{create_article_attrs.author_id} not found"} ==
               Articles.create_article(create_article_attrs)
    end

    test "returns an error changeset when slug already exists", %{
      user1: author,
      article: article
    } do
      create_article_attrs = %{
        author_id: author.id,
        title: article.title,
        description: Faker.Lorem.sentence(),
        body: Faker.Lorem.paragraph(),
        tag_list: Faker.Lorem.words()
      }

      assert {:error, %Ecto.Changeset{} = changeset} =
               Articles.create_article(create_article_attrs)

      assert "has already been taken" in errors_on(changeset, :slug)
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

  describe "get_article_by_slug/1" do
    test "returns the article", %{article: article} do
      assert {:ok, %Article{} = got_article} = Articles.get_article_by_slug(article.slug)
      assert Map.delete(got_article, :author) == Map.delete(article, :author)
    end

    test "returns :not_found when the article is not found" do
      slug = Slug.slugify(Faker.Lorem.sentence())

      assert {:not_found, "Slug #{slug} not found"} ==
               Articles.get_article_by_slug(slug)
    end
  end

  describe "favorite_article/1" do
    test "favorites an article", %{user1: user, article: article} do
      assert {:ok, false} == Articles.is_favorited?(%{user_id: user.id, article_id: article.id})

      assert {:ok, nil} == Articles.favorite_article(%{user_id: user.id, article_id: article.id})

      assert {:ok, true} == Articles.is_favorited?(%{user_id: user.id, article_id: article.id})
    end

    test "returns :not_found when the user is not found", %{article: article} do
      user_id = Faker.UUID.v4()

      assert {:not_found, "User #{user_id} not found"} ==
               Articles.favorite_article(%{user_id: user_id, article_id: article.id})
    end

    test "returns :not_found when the article is not found", %{user1: user} do
      article_id = Faker.UUID.v4()

      assert {:not_found, "Article #{article_id} not found"} ==
               Articles.favorite_article(%{user_id: user.id, article_id: article_id})
    end
  end

  describe "get_favorites_count/1" do
    test "returns the favorites count", %{user1: user1, user2: user2, article: article} do
      assert {:ok, 0} == Articles.get_favorites_count(article.id)

      assert {:ok, nil} == Articles.favorite_article(%{user_id: user1.id, article_id: article.id})

      assert {:ok, 1} == Articles.get_favorites_count(article.id)

      assert {:ok, nil} == Articles.favorite_article(%{user_id: user2.id, article_id: article.id})

      assert {:ok, 2} == Articles.get_favorites_count(article.id)
    end

    test "does nothing when the article is already favorited", %{user1: user, article: article} do
      assert {:ok, nil} == Articles.favorite_article(%{user_id: user.id, article_id: article.id})

      assert {:ok, 1} == Articles.get_favorites_count(article.id)

      assert {:ok, nil} == Articles.favorite_article(%{user_id: user.id, article_id: article.id})

      assert {:ok, 1} == Articles.get_favorites_count(article.id)
    end

    test "returns :not_found when the article is not found" do
      article_id = Faker.UUID.v4()

      assert {:not_found, "Article #{article_id} not found"} ==
               Articles.get_favorites_count(article_id)
    end
  end
end
