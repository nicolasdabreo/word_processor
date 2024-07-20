defmodule Word.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      WordWeb.Endpoint,
      {Registry, keys: :unique, name: Word.Rooms.RoomRegistry},
      {DynamicSupervisor, strategy: :one_for_one, name: Word.Rooms.RoomManager},
      {Phoenix.PubSub, name: Word.PubSub}
    ]

    opts = [strategy: :one_for_one, name: Word.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    WordWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
