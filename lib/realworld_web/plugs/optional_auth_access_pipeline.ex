defmodule RealWorldWeb.OptionalAuthAccessPipeline do
  @moduledoc """
  See https://github.com/ueberauth/guardian#create-a-custom-pipeline
  """

  use Guardian.Plug.Pipeline,
    otp_app: :realworld,
    module: RealWorldWeb.Guardian,
    error_handler: RealWorldWeb.AuthErrorHandler

  plug Guardian.Plug.VerifySession, claims: %{"typ" => "access"}
  plug Guardian.Plug.VerifyHeader, claims: %{"typ" => "access"}
  plug Guardian.Plug.LoadResource, allow_blank: true
end
