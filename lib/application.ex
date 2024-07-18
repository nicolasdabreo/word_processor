defmodule Word.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      WordWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:word_processor, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Word.PubSub},
      # Start a worker by calling: Word.Worker.start_link(arg)
      # {Word.Worker, arg},
      # Start to serve requests, typically the last entry
      WordWeb.Endpoint,
      # Start the process registry
      {Registry, keys: :unique, name: Word.RoomRegistry},
      {DynamicSupervisor, strategy: :one_for_one, name: Word.RoomSupervisor}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Word.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    WordWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
