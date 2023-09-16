defmodule ExsemanticaWeb.Live.UserLive do
  @moduledoc """
  LiveView of an ExSemantica user.
  """
  use ExsemanticaWeb, :live_view

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"user"
  end
end
