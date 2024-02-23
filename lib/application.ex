defmodule WP.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      WPWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:word_processor, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: WP.PubSub},
      # Start a worker by calling: WP.Worker.start_link(arg)
      # {WP.Worker, arg},
      # Start to serve requests, typically the last entry
      WPWeb.Endpoint,
      # Start our Word Processor agent
      {WP, ""}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: WP.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    WPWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
