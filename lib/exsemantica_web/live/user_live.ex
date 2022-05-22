defmodule ExsemanticaWeb.UserLive do
  use ExsemanticaWeb, :live_view

  import Ecto.Query

  def mount(params, _session, socket) do
    # Be clearer...params are the user who we want to view.

    query = from u in Exsemantica.Content.User, where: fragment("lower(?)", u.handle) == ^String.downcase(params["user"])

    result = Exsemantica.Repo.one(query)

    {:ok, socket |> assign(:user_data, result)}
  end
  def render(assigns) do
    unless is_nil(assigns.user_data) do
      ~H"""
      <div class="w-screen h-screen">
        <div class="p-8 flex flex-row gap-8 items-start xl:w-2/3 m-auto w-full">
          <main class="basis-2/3">

              <div class="bg-indigo-200 rounded-lg drop-shadow-xl p-8 mb-8">
                  <h1 class="text-2xl">@<%= @user_data.handle %></h1>
                  <br>
                  <%= @user_data.biography %>
              </div>
          </main>
          <aside class="basis-1/3">
              <div class="bg-indigo-300 rounded-lg drop-shadow-xl p-8">
              </div>
              <br>
              <footer class="text-center"><small>ExSemantica v<%= :persistent_term.get(Exsemantica.Version) %> - <a href="https://github.com/ExSemantica/ExSemantica" class="underline decoration-sky-600 text-sky-600">Fork me on GitHub!</a></small></footer>
          </aside>
        </div>
      </div>
      """
    end
  end
end
