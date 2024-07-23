defmodule Word.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Registry, keys: :duplicate, name: Word.Rooms.RoomRegistry},
      {DynamicSupervisor, strategy: :one_for_one, name: Word.Rooms.RoomManager},
      {Phoenix.PubSub, name: Word.PubSub},
      WordWeb.Endpoint,
      WordWeb.Presence
    ]

    Word.Events.init_table()
    opts = [strategy: :one_for_all, name: Word.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    WordWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
