defmodule Exsemantica.Backbone do
  @moduledoc """
  Backend logic
  """
  use Supervisor

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    children = [
      {__MODULE__.PhoenixTracker, pubsub_server: Exsemantica.PubSub},
      __MODULE__.CountOnline
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
