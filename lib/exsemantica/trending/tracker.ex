defmodule Exsemantica.Trending.Tracker do
  @moduledoc """
  Tracks trending Aggregates
  """
  require Logger
  use GenServer

  @clear_timer 30000

  # ===========================================================================
  # Public-facing calls
  # ===========================================================================
  @doc """
  Starts the trend tracker and initializes its table.
  """
  def start_link(init_arg) do
    GenServer.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @doc """
  Increments a trend's popularity by one on the table.
  """
  def increment(trend) do
    GenServer.cast(__MODULE__, {:increment, trend})
  end

  @doc """
  Fetches a trend's popularity.
  """
  def fetch(trend) do
    GenServer.call(__MODULE__, {:fetch, trend})
  end

  @doc """
  Fetches the most popular *n* trends.

  Each trend is stored as a tuple `{name, popularity}`. This may change later.
  """
  def popular(n) do
    GenServer.call(__MODULE__, {:popular, n})
  end

  # ===========================================================================
  # Callbacks
  # ===========================================================================
  @impl true
  def init(_init_arg) do
    Logger.debug("Starting")
    Process.send_after(self(), :clear, @clear_timer)

    :mnesia.create_table(__MODULE__.Popularities,
      record_name: :popularity,
      type: :ordered_set,
      disc_copies: [Node.self()],
      index: ~w(trend)a,
      attributes: ~w(popularity trend)a
    )

    {:ok, []}
  end

  @impl true
  def handle_info(:clear, state) do
    Logger.debug("Clearing table...")
    :mnesia.clear_table(__MODULE__.Popularities)
    Process.send_after(self(), :clear, @clear_timer)

    {:noreply, state}
  end

  @impl true
  def handle_cast({:increment, trend}, state) do
    {:atomic, :ok} =
      :mnesia.transaction(fn ->
        popularity =
          case :mnesia.index_read(__MODULE__.Popularities, trend, :trend) do
            [{:popularity, where = {p, ^trend}, ^trend}] ->
              :mnesia.delete({__MODULE__.Popularities, where})
              p

            [] ->
              0
          end

        :mnesia.write(
          __MODULE__.Popularities,
          {:popularity, {popularity + 1, trend}, trend},
          :write
        )
      end)

    {:noreply, state}
  end

  @impl true
  def handle_call({:fetch, trend}, _from, state) do
    {:atomic, result} =
      :mnesia.transaction(fn ->
        case :mnesia.index_read(__MODULE__.Popularities, trend, :trend) do
          [{:popularity, {p, ^trend}, ^trend}] -> p
          [] -> 0
        end
      end)

    {:reply, {:ok, result}, state}
  end

  @impl true
  def handle_call({:popular, n}, _from, state) do
    {:atomic, result} =
      :mnesia.transaction(fn ->
        {items, _end_n} =
          :mnesia.foldr(&fold_popularity/2, {[], n}, __MODULE__.Popularities)

        items
      end)

    {:reply, {:ok, result}, state}
  end

  # ===========================================================================
  # Private functions
  # ===========================================================================
  defp fold_popularity(entry, {acc, i}) do
    if i > 0 do
      {:popularity, {p, _t}, trend} = entry
      {[{trend, p} | acc], i - 1}
    else
      {acc, 0}
    end
  end
end
