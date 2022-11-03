defmodule RealWorldWeb.UserView do
  use RealWorldWeb, :view
  alias RealWorldWeb.UserView

  def render("show.json", %{user: user, token: token}) do
    %{user: render_one(user, UserView, "user.json", token: token)}
  end

  def render("user.json", %{user: user, token: token}) do
    %{
      email: user.email,
      username: user.username,
      token: token,
      bio: user.bio,
      image: user.image
    }
  end
end
