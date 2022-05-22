defmodule ExsemanticaWeb.InterestLive do
  use ExsemanticaWeb, :live_view

  def mount(params, session, socket) do
    # Be clearer...params are the interest that we want to view.
    {:ok, socket}
  end
  def render(assigns) do
    ~H"""
    Test 456
    """
  end
end
