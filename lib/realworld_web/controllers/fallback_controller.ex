defmodule RealWorldWeb.FallbackController do
  @moduledoc """
  Translates controller action results into valid `Plug.Conn` responses.

  See `Phoenix.Controller.action_fallback/1` for more details.
  """
  use RealWorldWeb, :controller

  # This clause handles errors returned by Ecto's insert/update/delete.
  @impl true
  def call(conn, {:error, %Ecto.Changeset{} = changeset}) do
    conn
    |> put_status(:unprocessable_entity)
    |> put_view(RealWorldWeb.ErrorView)
    |> render("changeset.json", changeset: changeset)
  end

  def call(conn, {:error, :unauthorized}) do
    conn
    |> put_status(:unauthorized)
    |> put_view(RealWorldWeb.ErrorView)
    |> render("401.json")
  end

  # This clause is an example of how to handle resources that cannot be found.
  def call(conn, {:error, :not_found}) do
    conn
    |> put_status(:not_found)
    |> put_view(RealWorldWeb.ErrorView)
    |> render(:"404")
  end
end
