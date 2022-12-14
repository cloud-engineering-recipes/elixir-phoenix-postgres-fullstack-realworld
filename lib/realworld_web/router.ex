defmodule RealWorldWeb.Router do
  @moduledoc false

  use RealWorldWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {RealWorldWeb.LayoutView, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :ensure_authenticated do
    plug RealWorldWeb.AuthAccessPipeline
  end

  pipeline :optional_authenticated do
    plug RealWorldWeb.OptionalAuthAccessPipeline
  end

  scope "/", RealWorldWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  scope "/api", RealWorldWeb do
    pipe_through :api

    post "/users/login", UserController, :login
    post "/users", UserController, :register_user

    get "/tags", TagController, :get_tags
  end

  scope "/api", RealWorldWeb do
    pipe_through([:api, :ensure_authenticated])

    get "/user", UserController, :get_current_user
    put "/user", UserController, :update_user

    post "/profiles/:username/follow", ProfileController, :follow_user
    delete "/profiles/:username/follow", ProfileController, :unfollow_user

    get "/articles/feed", ArticleController, :feed_articles
    post "/articles", ArticleController, :create_article
    post "/articles/:slug/comments", CommentController, :add_comment
    post "/articles/:slug/favorite", ArticleController, :favorite_article
    put "/articles/:slug", ArticleController, :update_article
    delete "/articles/:slug/comments/:id", CommentController, :delete_comment
    delete "/articles/:slug/favorite", ArticleController, :unfavorite_article
  end

  scope "/api", RealWorldWeb do
    pipe_through([:api, :optional_authenticated])

    get "/profiles/:username", ProfileController, :get_profile

    get "/articles/:slug/comments", CommentController, :get_article_comments
    get "/articles/:slug", ArticleController, :get_article
    get "/articles", ArticleController, :list_articles
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: RealWorldWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through :browser

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
