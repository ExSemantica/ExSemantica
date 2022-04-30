defmodule ExsemanticaWeb.UserLive do
  use ExsemanticaWeb, :live_view

  def mount(params, session, socket) do
    # Be clearer...params are the user who we want to view.
    {:ok, socket}
  end
  def render(assigns) do
    ~H"""
    Test 123
    """
  end
end
