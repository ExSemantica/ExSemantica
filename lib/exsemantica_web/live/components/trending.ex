defmodule ExsemanticaWeb.Components.Trending do
  @moduledoc """
  A live component that shows what is trending, viewable in the "all" psuedo
  aggregate.
  """
  use ExsemanticaWeb, :live_component

  def render(assigns) do
    ~H"""
    <div>
      <p><.icon name="hero-arrow-trending-up" /> <b>Trends</b></p>
      <%= if @trends == [] do %>
        <p class="pl-8">Nothing is trending</p>
      <% else %>
        <%= for {trend, count} <- @trends do %>
          <p class="pl-8">
            <.link class="text-blue-800" navigate={~p"/s/#{trend}"}>/s/<%= trend %></.link>
            (<%= count %>)
          </p>
        <% end %>
      <% end %>
      <br />
      <p class="text-xs">Updated <%= @stamp %></p>
    </div>
    """
  end
end
