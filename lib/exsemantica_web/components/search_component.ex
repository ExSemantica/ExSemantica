defmodule ExsemanticaWeb.SearchComponent do
  # Big TODO is to port this back.
  use ExsemanticaWeb, :live_component

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div>
      <.form let={f} for={:search} phx-change="query_preflight" phx-submit="query_submit">
        <%= text_input f, :entry, [type: "search", placeholder: "🔍 Search trends...", class: "bg-indigo-200 rounded-full w-full mb-4 p-1/4 drop-shadow-md"] %>
      </.form>
    </div>
    """
  end
end
