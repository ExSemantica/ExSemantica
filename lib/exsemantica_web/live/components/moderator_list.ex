defmodule ExsemanticaWeb.Components.ModeratorList do
  @moduledoc """
  A live component that lets you get a listing of aggregate moderators.
  """
  use ExsemanticaWeb, :live_component

  import ExsemanticaWeb.Gettext

  def render(assigns) do
    ~H"""
    <div>
      <p><.icon name="hero-wrench-screwdriver" />
      <b><%= gettext("Moderators: ") %></b><%= assigns.moderators |> moderator_joiner %></p>
      <br />
    </div>
    """
  end

  defp moderator_joiner(mods) when mods == [], do: gettext("None")

  defp moderator_joiner(mods) do
    mods
    |> Enum.map(&"/u/#{&1.handle}")
    |> Enum.join(", ")
  end
end
