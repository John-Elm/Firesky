defmodule Firesky.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      FireskyWeb.Telemetry,
      Firesky.Repo,
      {DNSCluster, query: Application.get_env(:firesky, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Firesky.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Firesky.Finch},
      # Start a worker by calling: Firesky.Worker.start_link(arg)
      # {Firesky.Worker, arg},
      # Start to serve requests, typically the last entry
      FireskyWeb.Endpoint
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Firesky.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    FireskyWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
