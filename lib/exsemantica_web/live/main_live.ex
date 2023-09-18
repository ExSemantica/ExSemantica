defmodule ExsemanticaWeb.MainLive do
  @moduledoc """
  A live view that handles most logic in the site.
  """
  require Logger
  use ExsemanticaWeb, :live_view
  import ExsemanticaWeb.Gettext

  @users_time 1_000
  @trend_time 1_000
  @trend_max 5

  alias Exsemantica.Backbone.Authentication, as: Authentication
  alias Exsemantica.Backbone.PhoenixTracker, as: Tracker
  alias Exsemantica.Backbone.CountOnline, as: CountOnline
  alias Exsemantica.Trending.Tracker, as: Trending

  embed_templates "layouts/*"

  # ===========================================================================
  # Mount
  # ===========================================================================
  def mount(_params, _session, socket) when socket.assigns.live_action == :redirect_to_all do
    {:ok, socket |> redirect(to: ~p"/s/all")}
  end

  def mount(params, session, socket) do
    if socket |> connected? do
      socket = socket |> assign(loading: false) |> push_event("transition-loader", %{})
      post_mount(params, session, socket)
    else
      {:ok, socket |> assign(loading: true)}
    end
  end

  # ===========================================================================
  # After mounting has finished
  # ===========================================================================
  def post_mount(%{"handle" => handle}, _session, socket)
      when socket.assigns.live_action == :user do
    {:ok, socket |> do_auth |> assign(%{otype: :user, ident: handle})}
  end

  def post_mount(%{"aggregate" => "all"}, _session, socket)
      when socket.assigns.live_action == :aggregate do
    {:ok, trends} = Trending.popular(@trend_max)
    Process.send_after(self(), :trends_heartbeat, @trend_time)

    {:ok,
     socket
     |> do_auth
     |> assign(%{otype: :aggregate, ident: nil, trends: trends, stamp: get_timestamp()})}
  end

  def post_mount(%{"aggregate" => aggregate}, _session, socket)
      when socket.assigns.live_action == :aggregate do
    Tracker.online(self(), aggregate)
    Process.send_after(self(), :users_heartbeat, @users_time)
    {:ok, users} = CountOnline.get("aggregate:" <> aggregate)
    Trending.increment(aggregate)

    {:ok,
     socket
     |> do_auth
     |> assign(%{otype: :aggregate, ident: aggregate, users: users, stamp: get_timestamp()})}
  end

  # ===========================================================================
  # Handle timer events
  # ===========================================================================
  def handle_info(:trends_heartbeat, socket) do
    {:ok, trends} = Trending.popular(@trend_max)

    Process.send_after(self(), :trends_heartbeat, @trend_time)

    send_update(ExsemanticaWeb.Components.Trending,
      id: "trending",
      trends: trends,
      stamp: get_timestamp()
    )

    {:noreply, socket}
  end

  def handle_info(:users_heartbeat, socket) do
    {:ok, users} = CountOnline.get("aggregate:" <> socket.assigns.ident)

    Process.send_after(self(), :users_heartbeat, @users_time)

    send_update(ExsemanticaWeb.Components.WhosOnline,
      id: "whos-online",
      users: users,
      stamp: get_timestamp()
    )

    {:noreply, socket}
  end

  # ===========================================================================
  # Render
  # ===========================================================================
  def render(assigns) do
    if assigns.loading do
      ~H"""
      <.lloader />
      """
    else
      case assigns.otype do
        :aggregate when is_nil(assigns.ident) ->
          ~H"""
          <.lheader myuser={@myuser} />
          <.lbody_all trends={@trends} stamp={@stamp} />
          <.lfooter />
          """

        :aggregate ->
          ~H"""
          <.lheader myuser={@myuser} />
          <.lbody_aggregate aggregate={@ident} users={@users} stamp={@stamp} />
          <.lfooter />
          """

        :user ->
          ~H"""
          <.lheader myuser={@myuser} />
          <.lbody_user user={@ident} />
          <.lfooter />
          """
      end
    end
  end

  # ===========================================================================
  # Private functions
  # ===========================================================================
  defp get_handle(socket) do
    token = get_connect_params(socket)["exsemantica_token"]

    case Authentication.verify_token(token) do
      {:ok, user} ->
        {:ok, user.handle}

      {:error, error} ->
        {:error, error}
    end
  end

  defp do_auth(socket) do
    case socket |> get_handle do
      {:ok, myuser} ->
        socket |> assign(myuser: myuser)

      {:error, :token_expired} ->
        socket
        |> assign(myuser: nil)
        |> put_flash(:error, gettext("Your session expired."))
        |> push_event("clear-token", %{})

      {:error, _error} ->
        socket |> assign(myuser: nil)
    end
  end

  defp get_timestamp(), do: DateTime.utc_now(:second) |> DateTime.to_iso8601()
end
