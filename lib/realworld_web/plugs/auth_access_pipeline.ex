defmodule RealWorldWeb.AuthAccessPipeline do
  @moduledoc """
  See https://github.com/ueberauth/guardian#create-a-custom-pipeline
  """

  use Guardian.Plug.Pipeline,
    otp_app: :realworld,
    module: RealWorldWeb.Guardian,
    error_handler: RealWorldWeb.AuthErrorHandler

  plug Guardian.Plug.VerifyHeader, scheme: "Token"
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource
end
