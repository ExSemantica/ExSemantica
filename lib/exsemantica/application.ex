defmodule Exsemantica.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    topologies = Application.get_env(:libcluster, :topologies)

    Exsemantica.IRC.rehash()
    Exsemantica.ApplicationInfo.refresh()

    children = [
      ExsemanticaWeb.Telemetry,
      Exsemantica.Repo,
      # {DNSCluster, query: Application.get_env(:exsemantica, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Exsemantica.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Exsemantica.Finch},
      # Start a worker by calling: Exsemantica.Worker.start_link(arg)
      # {Exsemantica.Worker, arg},
      ExsemanticaWeb.ChatPresence,
      # Start to serve requests, typically the last entry
      ExsemanticaWeb.Endpoint,

      {Exsemantica.IRC.UserSupervisor, %{max_children: 512}},
      {ThousandIsland, port: 6667, handler_module: Exsemantica.IRC.Handler}
    ]

    # Check if clustering topologies are nil (usually the case in dev)
    children =
      if is_nil(topologies) do
        children
      else
        [{Cluster.Supervisor, [topologies, [name: Exsemantica.ClusterSupervisor]]} | children]
      end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Exsemantica.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ExsemanticaWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
