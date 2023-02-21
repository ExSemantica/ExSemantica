defmodule ExsemanticaWeb.NavbarComponent do
  use ExsemanticaWeb, :live_component
  alias Phoenix.LiveView.JS

  @transition 500

  def render(assigns) do
    ~H"""
    <nav class="h-16 bg-gray-100 shadow-lg w-full absolute">
        <%= live_redirect to: Routes.home_path(@socket, :timeline) do %>
            <img src={Routes.static_path(@socket, "/images/logo.png")} alt="ExSemantica logo" class="h-full p-3 float-left">
        <% end %>

         <div phx-click={menu_show()} >
            <Heroicons.Solid.bars_3 class="absolute h-full p-4 right-0"/>
        </div>

        <div id="navbar-menu" phx-remove={menu_hide()}
            class="absolute shadow-lg mt-16 right-0 w-1/3 bg-gray-200">
            <div id="navbar-menu-content" class="p-4"
            phx-click-away={menu_hide()}
            phx-window-keydown={menu_hide()}
            phx-key="escape">
                test
            </div>
        </div>
    </nav>
    """
  end

  @doc """
  Hides the menu of the nav bar
  """
  def menu_hide(js \\ %JS{}) do
    js
    |> JS.hide(to: "#navbar-menu-content")
    |> JS.hide(transition: {"transition ease-linear duration-#{@transition}", "h-1/2", "h-0"}, to: "#navbar-menu", time: @transition)
  end

  @doc """
  Shows the menu of the nav bar
  """
  def menu_show(js \\ %JS{}) do
    js
    |> JS.show(transition: {"transition ease-linear duration-#{@transition}", "h-1/2", "h-auto"}, to: "#navbar-menu", time: @transition)
    |> JS.show(to: "#navbar-menu-content")
  end
end
