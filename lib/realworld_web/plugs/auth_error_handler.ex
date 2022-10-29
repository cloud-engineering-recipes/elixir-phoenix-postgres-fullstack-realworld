defmodule RealWorldWeb.AuthErrorHandler do
  @moduledoc """
  See https://github.com/ueberauth/guardian#plug-error-handlers
  """

  import Plug.Conn

  @behaviour Guardian.Plug.ErrorHandler

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {_type, _reason}, _opts) do
    body = Jason.encode!(%{errors: %{body: ["unauthorized"]}})

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(401, body)
  end
end
