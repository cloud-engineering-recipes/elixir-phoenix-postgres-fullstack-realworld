defmodule RealWorldWeb.UserView do
  use RealWorldWeb, :view
  alias RealWorldWeb.UserView

  def render("show.json", %{user: user, token: token}) do
    %{user: Map.merge(render_one(user, UserView, "user.json"), %{token: token})}
  end

  def render("user.json", %{user: user}) do
    %{
      email: user.email,
      username: user.username,
      bio: user.bio,
      image: user.image
    }
  end
end
