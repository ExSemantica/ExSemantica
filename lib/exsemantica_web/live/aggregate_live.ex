defmodule ExsemanticaWeb.Live.AggregateLive do
  @moduledoc """
  LiveView of an ExSemantica aggregate.
  """
  require Logger
  alias Exsemantica.Backbone.PhoenixTracker, as: Tracker
  alias Exsemantica.Backbone.CountOnline, as: CountOnline
  alias Exsemantica.Trending.Tracker, as: Trending
  use ExsemanticaWeb, :live_view
  import ExsemanticaWeb.Gettext

  @online_time 1000
  @trend_time 5000
  @trend_max 5

  def mount(%{"aggregate" => "all"}, _session, socket) do
    {:ok, trends} = Trending.popular(@trend_max)
    Process.send_after(self(), :trendbeat, @trend_time)
    {:ok, socket |> assign(community: nil, trends: trends)}
  end

  def mount(%{"aggregate" => community}, _session, socket) do
    Logger.debug("Socket enters community '#{community}'")
    Tracker.online(self(), community)
    Trending.increment(community)

    {:ok, count} = CountOnline.get("aggregate:" <> community)
    Process.send_after(self(), :heartbeat, @online_time)

    {:ok, socket |> assign(%{community: community, users: count})}
  end

  def handle_info(:heartbeat, socket) do
    {:ok, count} = CountOnline.get("aggregate:" <> socket.assigns.community)
    Process.send_after(self(), :heartbeat, @online_time)

    {:noreply, socket |> assign(users: count)}
  end

  def handle_info(:trendbeat, socket) do
    {:ok, trends} = Trending.popular(@trend_max)
    Process.send_after(self(), :trendbeat, @trend_time)

    {:noreply, socket |> assign(trends: trends)}
  end

  def render(assigns) do
    if is_nil(assigns.community) do
    if assigns.trends == [] do
    end
      ~H"""
      <main class="bg-gray-200 m-8 p-8 shadow-2xl w-2/3 h-min">
        <h1 class="text-2xl p-4">Personalized feed</h1>
        <div class="pl-4">TODO: 'All' page here</div>
      </main>
      <aside class="bg-slate-200 m-8 p-8 shadow-2xl w-1/3 h-min">
        <p><.icon name="hero-arrow-trending-up"/> <b>Trends</b></p>
        <%= if @trends == [] do %>
          <p class="pl-8">Nothing is trending</p>
        <%= else %>
          <%= for {trend, count} <- @trends do %>
            <p class="pl-8"><.link class="text-blue-800" href={~p"/s/#{trend}"}>/s/<%= trend %></.link> (<%= count %>)</p>
          <% end %>
        <% end %>
      </aside>
      """
    else
      ~H"""
      <main class="bg-gray-200 m-8 p-8 shadow-2xl w-2/3 h-min">
        <h1 class="text-2xl p-4">/s/<%= @community %> feed</h1>
        <div class="pl-4">TODO: 'Community' page here</div>
      </main>
      <aside class="bg-slate-200 m-8 p-8 shadow-2xl w-1/3 h-min">
        <p><.icon name="hero-user-circle"/> <b><%= ngettext("%{count} user online", "%{count} users online", @users) %></b></p>
      </aside>
      """
    end
  end
end
