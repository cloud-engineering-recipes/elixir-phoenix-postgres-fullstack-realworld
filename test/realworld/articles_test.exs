defmodule RealWorld.ArticlesTest do
  use RealWorld.DataCase, async: true

  import RealWorld.Factory
  import RealWorld.TestUtils
  alias RealWorld.{Articles, Articles.Article}

  describe "create_article/1" do
    test "returns an article" do
      author = insert(:user)

      create_article_attrs = %{
        author_id: author.id,
        title: " My Awesome Article! It is really good! ",
        description: Faker.Lorem.sentence(),
        body: Faker.Lorem.paragraph(),
        tags: [
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

      assert article.tags |> Enum.map(fn tag -> tag.name end) == [
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
        tags: Faker.Lorem.words()
      }

      assert {:not_found, "User #{create_article_attrs.author_id} not found"} ==
               Articles.create_article(create_article_attrs)
    end

    test "returns an error changeset when slug already exists" do
      author = insert(:user)
      article = insert(:article)

      create_article_attrs = %{
        author_id: author.id,
        title: article.title,
        description: Faker.Lorem.sentence(),
        body: Faker.Lorem.paragraph(),
        tags: Faker.Lorem.words()
      }

      assert {:error, %Ecto.Changeset{} = changeset} =
               Articles.create_article(create_article_attrs)

      assert "has already been taken" in errors_on(changeset, :slug)
    end
  end

  describe "update_article/2" do
    test "returns an article" do
      author = insert(:user)
      article = insert(:article, author: author)

      update_article_attrs = %{
        title: Faker.Lorem.sentence(),
        description: Faker.Lorem.sentence(),
        body: Faker.Lorem.paragraph(),
        tags: [
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

      assert {:ok, %Article{} = updated_article} =
               Articles.update_article(article.id, update_article_attrs)

      assert updated_article.id == article.id
      assert updated_article.author_id == article.author_id
      assert updated_article.slug == Slug.slugify(update_article_attrs.title)
      assert updated_article.title == update_article_attrs.title
      assert updated_article.description == update_article_attrs.description
      assert updated_article.body == update_article_attrs.body

      assert updated_article.tags |> Enum.map(fn tag -> tag.name end) == [
               "lower1",
               "lower2",
               "upper1",
               "upper2",
               "mixed1",
               "mixed2",
               "mixed3"
             ]

      with {:ok, %Article{} = got_article} <- Articles.get_article_by_id(updated_article.id) do
        assert updated_article == got_article
      end
    end

    test "returns :not_found when the article is not found" do
      article_id = Faker.UUID.v4()

      update_article_attrs = %{
        title: Faker.Lorem.sentence(),
        description: Faker.Lorem.sentence(),
        body: Faker.Lorem.paragraph(),
        tags: Faker.Lorem.words()
      }

      assert {:not_found, "Article #{article_id} not found"} ==
               Articles.update_article(article_id, update_article_attrs)
    end

    test "returns an error changeset when slug already exists" do
      existing_article = insert(:article)
      article = insert(:article)

      update_article_attrs = %{
        title: existing_article.title,
        description: Faker.Lorem.sentence(),
        body: Faker.Lorem.paragraph(),
        tags: Faker.Lorem.words()
      }

      assert {:error, %Ecto.Changeset{} = changeset} =
               Articles.update_article(article.id, update_article_attrs)

      assert "has already been taken" in errors_on(changeset, :slug)
    end
  end

  describe "get_article_by_id/1" do
    test "returns the article" do
      article = insert(:article)

      assert {:ok, %Article{} = got_article} = Articles.get_article_by_id(article.id)
      assert got_article == article
    end

    test "returns :not_found when the article is not found" do
      article_id = Faker.UUID.v4()

      assert {:not_found, "Article #{article_id} not found"} ==
               Articles.get_article_by_id(article_id)
    end
  end

  describe "get_article_by_slug/1" do
    test "returns the article" do
      article = insert(:article)

      assert {:ok, %Article{} = got_article} = Articles.get_article_by_slug(article.slug)
      assert got_article == article
    end

    test "returns :not_found when the article is not found" do
      slug = Slug.slugify(Faker.Lorem.sentence())

      assert {:not_found, "Slug #{slug} not found"} ==
               Articles.get_article_by_slug(slug)
    end
  end

  describe "list_articles/1" do
    test "returns articles ordered by most recent when given no filters" do
      article1 = insert(:article, inserted_at: Faker.DateTime.backward(1))
      article2 = insert(:article)

      assert {:ok, articles} = Articles.list_articles()

      assert articles == [article2, article1]
    end

    test "returns articles when given tag filter" do
      tag1 = insert(:tag, name: "tag1")
      tag2 = insert(:tag, name: "tag2")

      article1 = insert(:article, tags: [tag1], inserted_at: Faker.DateTime.backward(1))
      article2 = insert(:article, tags: [tag1])
      article3 = insert(:article, tags: [tag1, tag2], inserted_at: Faker.DateTime.backward(2))
      _article4 = insert(:article, tags: [tag2], inserted_at: Faker.DateTime.backward(1))
      _article5 = insert(:article, tags: [tag2])

      assert {:ok, articles} = Articles.list_articles(%{tag: tag1.name})
      assert articles == [article2, article1, article3]
    end

    test "returns articles when given author_id filter" do
      author = insert(:user)
      article1 = insert(:article, author: author, inserted_at: Faker.DateTime.backward(1))
      article2 = insert(:article, author: author)
      insert(:article)

      assert {:ok, articles} = Articles.list_articles(%{author_id: author.id})
      assert articles == [article2, article1]
    end
  end

  describe "favorite_article/1" do
    test "favorites an article" do
      user = insert(:user)
      article = insert(:article)

      assert {:ok, false} == Articles.is_favorited?(user.id, article.id)

      assert {:ok, nil} == Articles.favorite_article(user.id, article.id)

      assert {:ok, true} == Articles.is_favorited?(user.id, article.id)
    end

    test "returns :not_found when the user is not found" do
      user_id = Faker.UUID.v4()
      article = insert(:article)

      assert {:not_found, "User #{user_id} not found"} ==
               Articles.favorite_article(user_id, article.id)
    end

    test "returns :not_found when the article is not found" do
      user = insert(:user)

      article_id = Faker.UUID.v4()

      assert {:not_found, "Article #{article_id} not found"} ==
               Articles.favorite_article(user.id, article_id)
    end
  end

  describe "get_favorites_count/1" do
    test "returns the favorites count" do
      user1 = insert(:user)
      user2 = insert(:user)
      article = insert(:article)

      assert {:ok, 0} == Articles.get_favorites_count(article.id)

      assert {:ok, nil} == Articles.favorite_article(user1.id, article.id)

      assert {:ok, 1} == Articles.get_favorites_count(article.id)

      assert {:ok, nil} == Articles.favorite_article(user2.id, article.id)

      assert {:ok, 2} == Articles.get_favorites_count(article.id)
    end

    test "does nothing when the article is already favorited" do
      user = insert(:user)
      article = insert(:article)

      assert {:ok, nil} == Articles.favorite_article(user.id, article.id)

      assert {:ok, 1} == Articles.get_favorites_count(article.id)

      assert {:ok, nil} == Articles.favorite_article(user.id, article.id)

      assert {:ok, 1} == Articles.get_favorites_count(article.id)
    end

    test "returns :not_found when the article is not found" do
      article_id = Faker.UUID.v4()

      assert {:not_found, "Article #{article_id} not found"} ==
               Articles.get_favorites_count(article_id)
    end
  end
end
