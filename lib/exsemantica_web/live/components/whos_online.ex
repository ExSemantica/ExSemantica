defmodule ExsemanticaWeb.Components.WhosOnline do
  @moduledoc """
  A live component that lets you view users online in an aggregate.
  """
  require Logger
  use ExsemanticaWeb, :live_component

  import ExsemanticaWeb.Gettext

  def render(assigns) do
    ~H"""
    <p>
      <.icon name="hero-user-circle" />
      <b><%= ngettext("%{count} user online", "%{count} users online", @users) %></b>
    </p>
    """
  end
end
