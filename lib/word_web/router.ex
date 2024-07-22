defmodule WordWeb.Router do
  use WordWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {WordWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug WordWeb.Persona
  end

  scope "/", WordWeb do
    pipe_through :browser

    live "/", RoomLive, :index
    live "/rooms/:name", WordLive, :index
  end
end
