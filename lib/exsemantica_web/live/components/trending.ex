defmodule ExsemanticaWeb.Components.Trending do
  @moduledoc """
  A live component that shows what is trending, viewable in the "all" psuedo
  aggregate.
  """
  use ExsemanticaWeb, :live_component

  import ExsemanticaWeb.Gettext

  def render(assigns) do
    ~H"""
    <div>
      <p><.icon name="hero-arrow-trending-up" /> <b><%= gettext("Trends") %></b></p>
      <%= if @trends == [] do %>
        <p class="pl-8"><%= gettext("Nothing is trending.") %></p>
      <% else %>
        <%= for {trend, count} <- @trends do %>
          <p class="pl-8">
            <.link class="text-blue-800" navigate={~p"/s/#{trend}"}>/s/<%= trend %></.link>
            (<%= count %>)
          </p>
        <% end %>
      <% end %>
      <br />
      <p class="text-xs"><%= gettext("Updated %{stamp}", stamp: @stamp) %></p>
    </div>
    """
  end
end
