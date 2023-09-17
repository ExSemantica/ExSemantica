defmodule ExsemanticaWeb.MainLive do
  @moduledoc """
  A live view that handles most logic in the site.
  """
  use ExsemanticaWeb, :live_view

  @users_time 1000
  @trend_time 1000
  @trend_max 5

  alias Exsemantica.Backbone.PhoenixTracker, as: Tracker
  alias Exsemantica.Backbone.CountOnline, as: CountOnline
  alias Exsemantica.Trending.Tracker, as: Trending

  embed_templates "layouts/*"

  def mount(_params, _session, socket) when socket.assigns.live_action == :redirect_to_all do
    {:ok, socket |> redirect(to: ~p"/s/all")}
  end

  def mount(%{"handle" => handle}, _session, socket) when socket.assigns.live_action == :user do
    {:ok, socket |> assign(%{otype: :user, ident: handle})}
  end

  def mount(%{"aggregate" => "all"}, _session, socket)
      when socket.assigns.live_action == :aggregate do
    {:ok, trends} = Trending.popular(@trend_max)
    Process.send_after(self(), :trends_heartbeat, @trend_time)
    {:ok, socket |> assign(%{otype: :aggregate, ident: nil, trends: trends})}
  end

  def mount(%{"aggregate" => aggregate}, _session, socket)
      when socket.assigns.live_action == :aggregate do
    Tracker.online(self(), aggregate)
    Process.send_after(self(), :users_heartbeat, @users_time)
    {:ok, users} = CountOnline.get("aggregate:" <> aggregate)
    Trending.increment(aggregate)

    {:ok, socket |> assign(%{otype: :aggregate, ident: aggregate, users: users})}
  end

  def handle_info(:trends_heartbeat, socket) do
    {:ok, trends} = Trending.popular(@trend_max)
    Process.send_after(self(), :trends_heartbeat, @trend_time)

    {:noreply, socket |> assign(trends: trends)}
  end

  def handle_info(:users_heartbeat, socket) do
    {:ok, users} = CountOnline.get("aggregate:" <> socket.assigns.ident)
    {:ok, socket |> assign(users: users)}

    Process.send_after(self(), :users_heartbeat, @users_time)
    {:noreply, socket}
  end

  def render(assigns) do
    case assigns.otype do
      :aggregate when is_nil(assigns.ident) ->
        ~H"""
        <.lheader />
        <.lbody_all trends={@trends} />
        <.lfooter />
        """

      :aggregate ->
        ~H"""
        <.lheader />
        <.lbody_aggregate aggregate={@ident} users={@users} />
        <.lfooter />
        """

      :user ->
        ~H"""
        <.lheader />
        <.lbody_user user={@ident} />
        <.lfooter />
        """
    end
  end
end
