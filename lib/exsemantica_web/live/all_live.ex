defmodule ExsemanticaWeb.Live.AllLive do
  @moduledoc """
  LiveView of the "all" ExSemantica aggregate.

  This redirects to "/s/all"
  """
  use ExsemanticaWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket |> redirect(to: "/s/all")}
  end

  def render(assigns) do
    ~H""
  end
end
