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
      if Map.has_key?(attrs, :author) do
        attrs.author
      else
        insert(:user)
      end

    tags =
      if Map.has_key?(attrs, :tags) do
        attrs.tags
      else
        []
      end

    inserted_at =
      if Map.has_key?(attrs, :inserted_at) do
        attrs.inserted_at
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
      if Map.has_key?(attrs, :name) do
        attrs.name
      else
        Faker.Lorem.word()
      end

    %RealWorld.Articles.Tag{
      name: name
    }
  end
end
