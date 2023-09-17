defmodule ExsemanticaWeb.Components.Trending do
  @moduledoc """
  A live component that shows what is trending, viewable in the "all" psuedo
  aggregate.
  """
  use ExsemanticaWeb, :live_component

  def render(assigns) do
    ~H"""
    <aside class="bg-slate-200 m-8 p-8 shadow-2xl w-1/3 h-min">
      <p><.icon name="hero-arrow-trending-up" /> <b>Trends</b></p>
      <%= if @trends == [] do %>
        <p class="pl-8">Nothing is trending</p>
      <% else %>
        <%= for {trend, count} <- @trends do %>
          <p class="pl-8">
            <.link class="text-blue-800" href={~p"/s/#{trend}"}>/s/<%= trend %></.link> (<%= count %>)
          </p>
        <% end %>
      <% end %>
    </aside>
    """
  end
end
