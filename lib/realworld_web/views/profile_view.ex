defmodule RealWorldWeb.ProfileView do
  use RealWorldWeb, :view
  alias RealWorldWeb.ProfileView

  def render("show.json", %{user: user, is_following: is_following}) do
    %{
      profile: render_one(user, ProfileView, "profile.json", is_following: is_following)
    }
  end

  def render("profile.json", %{profile: user, is_following: is_following}) do
    %{
      username: user.username,
      bio: user.bio,
      image: user.image,
      following: is_following
    }
  end
end
