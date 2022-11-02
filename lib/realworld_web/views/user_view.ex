defmodule RealWorldWeb.UserView do
  use RealWorldWeb, :view
  alias RealWorldWeb.UserView

  def render("show.json", %{user: user}) do
    %{user: render_one(user, UserView, "user.json")}
  end

  def render("user.json", %{user: user}) do
    user
  end
end
