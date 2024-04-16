defmodule Sketchy.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false
  alias Sketchy.GameRegistry
  alias Sketchy.GameSupervisor

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {NodeJS.Supervisor, [path: LiveSvelte.SSR.NodeJS.server_path(), pool_size: 4]},
      SketchyWeb.Telemetry,
      Sketchy.Repo,
      {DNSCluster, query: Application.get_env(:sketchy, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Sketchy.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Sketchy.Finch},
      # Start a worker by calling: Sketchy.Worker.start_link(arg)
      # {Sketchy.Worker, arg},
      # Start to serve requests, typically the last entry
      SketchyWeb.Endpoint,
      GameSupervisor,
      {Registry, [keys: :unique, name: GameRegistry.name()]}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Sketchy.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SketchyWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
