defmodule Exsemantica.Backbone.CountOnline do
  @moduledoc """
  Keeps track of who's online in an Aggregate.
  """
  require Logger
  use GenServer

  # ===========================================================================
  # Public-facing calls
  # ===========================================================================
  @doc """
  Starts the counter server.
  """
  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @doc """
  Adds the values of the diff into the counters.

  The values in the counters will always be non-negative.
  """
  def put(diff) do
    GenServer.cast(__MODULE__, {:put, diff})
  end

  @doc """
  Gets the count of online users for a topic, or 0 if nobody's online yet.
  """
  def get(topic) do
    GenServer.call(__MODULE__, {:get, topic})
  end

  # ===========================================================================
  # Callbacks
  # ===========================================================================
  @impl true
  def init(_init_arg) do
    Logger.debug("Starting")
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:put, diff}, state) do
    Logger.debug("Put diff #{inspect(diff)} into #{inspect(state)}")
    {:noreply, state |> Map.merge(diff, &resolve_delta/3)}
  end

  @impl true
  def handle_call({:get, topic}, _from, state) do
    {:reply, {:ok, state |> Map.get(topic, 0)}, state}
  end

  # ===========================================================================
  # Private functions
  # ===========================================================================
  defp resolve_delta(_key, value0, value1) do
    max(0, value0 + value1)
  end
end
