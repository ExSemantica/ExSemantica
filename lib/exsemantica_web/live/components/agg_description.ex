defmodule ExsemanticaWeb.Components.AggDescription do
  @moduledoc """
  A live component that lets you get a synopsis of an aggregate.
  """
  use ExsemanticaWeb, :live_component

  import ExsemanticaWeb.Gettext

  def render(assigns) do
    ~H"""
    <div>
      <h1 class="text-xl"><%= gettext("Viewing /s/%{ident}", ident: assigns.aggregate) %></h1>
      <p><%= gettext("Description: %{desc}", desc: assigns.description) %></p>
    </div>
    """
  end
end
