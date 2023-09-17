defmodule Exsemantica.Backbone.PhoenixTracker do
  @moduledoc """
  Tracker logic for the aggregate feeds.
  """
  require Logger
  alias Exsemantica.Backbone.CountOnline, as: CountOnline
  use Phoenix.Tracker

  # ===========================================================================
  # Public-facing calls
  # ===========================================================================
  @doc """
  Start keeping track of aggregate viewing.
  """
  def start_link([pubsub_server: server] = init_arg) do
    Phoenix.Tracker.start_link(__MODULE__, init_arg, pubsub_server: server, name: __MODULE__)
  end

  @doc """
  Mark this socket as viewing this aggregate.

  The socket should automatically untrack when the aggregate is closed.
  """
  def online(socket, topic) do
    Phoenix.Tracker.track(__MODULE__, self(), "aggregate:" <> topic, socket, %{})
  end

  # ===========================================================================
  # Callbacks
  # ===========================================================================
  @impl true
  def init(pubsub_server: server) do
    Logger.debug("Starting")
    {:ok, %{pubsub_server: server, node_name: Phoenix.PubSub.node_name(server)}}
  end

  @impl true
  def handle_diff(diff, state) do
    diff
    |> Enum.map(fn {topic, {joins, leaves}} ->
      {topic, length(joins) - length(leaves)}
    end)
    |> Map.new()
    |> CountOnline.put()

    {:ok, state}
  end
end
