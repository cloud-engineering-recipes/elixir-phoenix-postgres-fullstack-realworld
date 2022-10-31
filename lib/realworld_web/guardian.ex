defmodule RealWorldWeb.Guardian do
  @moduledoc """
  This module is required by Guardian. See https://github.com/ueberauth/guardian#installation
  """

  use Guardian, otp_app: :realworld

  require Logger

  alias RealWorld.{Users, Users.User}

  def subject_for_token(%User{} = user, _claims) do
    {:ok, user.id}
  end

  def subject_for_token(_, _) do
    {:error, "Unknown resource type"}
  end

  def resource_from_claims(%{"sub" => user_id}) do
    Users.get_user_by_id(user_id)
  end

  def resource_from_claims(_claims) do
    {:error, "Unknown resource type"}
  end
end
