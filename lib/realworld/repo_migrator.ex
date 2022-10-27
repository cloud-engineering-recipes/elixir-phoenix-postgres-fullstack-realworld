defmodule Realworld.Repo.Migrator do
  @moduledoc """
  Runs migrations inside of a release.
  """
  use GenServer
  require Logger

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], [])
  end

  def init(_) do
    migrate!()
    {:ok, nil}
  end

  def migrate! do
    path = Application.app_dir(:realworld, "priv/repo/migrations")

    Ecto.Migrator.run(Realworld.Repo, path, :up, all: true)
  end
end
