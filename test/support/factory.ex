defmodule RealWorld.Factory do
  @moduledoc """
  ExMachina factory. See https://hexdocs.pm/ex_machina/readme.html#ecto
  """
  use ExMachina.Ecto, repo: RealWorld.Repo

  def user_factory do
    password = List.to_string(Faker.Lorem.characters())

    %RealWorld.Users.User{
      email: Faker.Internet.email(),
      username: Faker.Internet.user_name(),
      password: password,
      password_hash: Argon2.hash_pwd_salt(password),
      bio: Faker.Lorem.paragraph(),
      image: Faker.Internet.url()
    }
  end

  def article_factory(attrs) do
    author =
      if author = attrs[:author] do
        author
      else
        insert(:user)
      end

    tags =
      if tags = attrs[:tags] do
        tags
      else
        []
      end

    inserted_at =
      if inserted_at = attrs[:inserted_at] do
        inserted_at
      else
        nil
      end

    title = Faker.Lorem.sentence()

    %RealWorld.Articles.Article{
      author_id: author.id,
      title: title,
      slug: Slug.slugify(title),
      description: Faker.Lorem.sentence(),
      body: Faker.Lorem.paragraph(),
      tags: tags,
      inserted_at: inserted_at
    }
  end

  def tag_factory(attrs) do
    name =
      if name = attrs[:name] do
        name
      else
        insert(:name)
      end

    %RealWorld.Articles.Tag{
      name: name
    }
  end

  def comment_factory(attrs) do
    user =
      if user = attrs[:user] do
        user
      else
        insert(:user)
      end

    article =
      if article = attrs[:article] do
        article
      else
        insert(:article)
      end

    body =
      if body = attrs[:body] do
        body
      else
        Faker.Lorem.paragraph()
      end

    %RealWorld.Articles.Comment{
      user_id: user.id,
      article_id: article.id,
      body: body
    }
  end
end
