defmodule RealWorld.TestUtils do
  @moduledoc """
  Test utils.
  """

  use RealWorldWeb.ConnCase

  alias RealWorld.Users.User

  def errors_on(changeset, field) do
    for {message, opts} <- Keyword.get_values(changeset.errors, field) do
      Enum.reduce(opts, message, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end
  end

  def secure_conn(conn, user_id) do
    {:ok, token, _} =
      %User{id: user_id} |> RealWorldWeb.Guardian.encode_and_sign(%{}, token_type: :access)

    conn
    |> put_req_header("accept", "application/json")
    |> put_req_header("authorization", "Bearer #{token}")
  end
end
