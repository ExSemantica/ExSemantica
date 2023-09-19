defmodule ExsemanticaWeb.Components.AllSearch do
  @moduledoc """
  A live component that lets you search for aggregates and users.
  """
  use ExsemanticaWeb, :live_component

  def render(assigns) do
    ~H"""
    <div>
      <.form :let={f} class="mb-3" for={%{}} phx-change="all-search-change" phx-submit="all-search-enter">
        <.input field={f[:search]} value="" placeholder="Search ExSemantica..." />
      </.form>
      <%= if @results != "" do %>
        <p><.icon name="hero-magnifying-glass" /> <b>Search results</b></p>
        <p class="pl-8"><%= @results %></p>
        <br>
      <% end %>
    </div>
    """
  end
end
