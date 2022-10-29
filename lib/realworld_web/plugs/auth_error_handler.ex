defmodule RealWorldWeb.AuthErrorHandler do
  @moduledoc """
  See https://github.com/ueberauth/guardian#plug-error-handlers
  """

  require Logger

  import Plug.Conn

  @behaviour Guardian.Plug.ErrorHandler

  @impl Guardian.Plug.ErrorHandler
  def auth_error(conn, {type, reason}, _opts) do
    Logger.error("auth_error! conn: #{inspect(conn)}; type #{type}; reason #{reason}")

    body = Jason.encode!(%{errors: %{body: ["unauthorized"]}})

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(401, body)
  end
end
