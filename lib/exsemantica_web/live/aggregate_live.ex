defmodule ExsemanticaWeb.Live.AggregateLive do
  @moduledoc """
  LiveView of an ExSemantica aggregate.
  """
  require Logger
  alias Exsemantica.Backbone.PhoenixTracker, as: Tracker
  alias Exsemantica.Backbone.CountOnline, as: CountOnline
  use ExsemanticaWeb, :live_view
  import ExsemanticaWeb.Gettext

  @refresh_time 1000

  def mount(%{"aggregate" => "all"}, _session, socket) do
    {:ok, socket |> assign(community: nil)}
  end

  def mount(%{"aggregate" => community}, _session, socket) do
    Logger.debug("Socket enters community '#{community}'")
    Tracker.online(self(), community)

    {:ok, count} = CountOnline.get("aggregate:" <> community)
    Process.send_after(self(), :heartbeat, @refresh_time)

    {:ok, socket |> assign(%{community: community, users: count})}
  end

  def handle_info(:heartbeat, socket) do
    {:ok, count} = CountOnline.get("aggregate:" <> socket.assigns.community)
    Process.send_after(self(), :heartbeat, @refresh_time)

    {:noreply, socket |> assign(users: count)}
  end

  def render(assigns) do
    if is_nil(assigns.community) do
      ~H"""
      <main class="bg-gray-200 m-8 p-8 shadow-2xl w-2/3 h-min">
        <h1 class="text-2xl p-4">Personalized feed</h1>
        <div class="pl-4">TODO: 'All' page here</div>
      </main>
      <aside class="bg-slate-200 m-8 p-8 shadow-2xl w-1/3 h-min">
        TODO: Trends here
      </aside>
      """
    else
      ~H"""
      <main class="bg-gray-200 m-8 p-8 shadow-2xl w-2/3 h-min">
        <h1 class="text-2xl p-4">/s/<%= @community %> feed</h1>
        <div class="pl-4">TODO: 'Community' page here</div>
      </main>
      <aside class="bg-slate-200 m-8 p-8 shadow-2xl w-1/3 h-min">
        <.icon name="hero-user-circle"/> <%= ngettext("%{count} user online", "%{count} users online", @users) %>
      </aside>
      """
    end
  end
end
