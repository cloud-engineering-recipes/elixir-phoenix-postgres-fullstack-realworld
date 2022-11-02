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

  def article_factory do
    title = Faker.Lorem.sentence()

    %RealWorld.Articles.Article{
      title: title,
      slug: Slug.slugify(title),
      description: Faker.Lorem.sentence(),
      body: Faker.Lorem.paragraph(),
      tag_list: ["tag1", "tag2"],
      author: build(:user)
    }
  end
end
