defmodule Exsemantica.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Exsemantica.ApplicationInfo.reset()

    children = [
      # Starts a worker by calling: Exsemantica.Worker.start_link(arg)
      # {Exsemantica.Worker, arg}
      {Bandit, plug: Exsemantica.API},
      Exsemantica.Repo,
      Exsemantica.Cache
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Exsemantica.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
