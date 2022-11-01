defmodule RealWorldWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use RealWorldWeb, :controller

  def call(conn, {:unauthorized, _}) do
    conn
    |> put_status(:unauthorized)
    |> put_view(RealWorldWeb.ErrorView)
    |> render("401.json", %{error_messages: ["Unauthorized"]})
  end

  def call(conn, {:not_found, error_message}) do
    conn
    |> put_status(:not_found)
    |> put_view(RealWorldWeb.ErrorView)
    |> render("404.json", %{error_messages: [error_message]})
  end

  # This clause handles errors returned by Ecto's insert/update/delete.
  @impl true
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(RealWorldWeb.ErrorView)
    |> render("changeset.json", changeset: changeset)
  end
end
