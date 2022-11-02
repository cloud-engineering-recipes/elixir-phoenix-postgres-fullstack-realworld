defmodule RealWorldWeb.ProfileView do
  use RealWorldWeb, :view
  alias RealWorldWeb.ProfileView

  def render("show.json", %{profile: profile}) do
    %{
      profile: render_one(profile, ProfileView, "profile.json")
    }
  end

  def render("profile.json", %{profile: profile}) do
    profile
  end
end
