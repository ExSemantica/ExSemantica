defmodule ExsemanticaWeb.IndexLive do
  use ExsemanticaWeb, :live_view

  alias ExsemanticaWeb.Types.Handle128

  def mount(_params, _session, socket) do
    {:ok, socket |> assign(:trend_search_status, "Please enter your query.")}
  end

  def render(assigns) do
    ~H"""
    <div class="w-screen h-screen">
      <div class="p-8 flex flex-row gap-8 items-start xl:w-2/3 m-auto w-full">
        <main class="basis-2/3">
            <div class="bg-indigo-200 rounded-lg drop-shadow-xl p-8 mb-8">
                <h1 class="text-2xl">Welcome to ExSemantica!</h1>
                <p><i>A free and open source microblogging and messaging platform for people who share interests.</i></p>
                <br>
                <p>Check the sidebar to see what's popular. Below is the interest feed.</p>
            </div>
            <div class="bg-indigo-200 rounded-lg drop-shadow-xl p-8 mb-8">
                <h2 class="text-xl">Testing 123</h2>
                Lorem ipsum dolor sit amet
            </div>
        </main>
        <aside class="basis-1/3">
            <div class="bg-indigo-300 rounded-lg drop-shadow-xl p-8">
                <.live_component module={ExsemanticaWeb.SearchComponent} id="search" />
                <i><%= @trend_search_status %></i>
            </div>
            <br>
            <footer class="text-center"><small>ExSemantica v<%= :persistent_term.get(Exsemantica.Version) %> - <a href="https://github.com/ExSemantica/ExSemantica" class="underline decoration-sky-600 text-sky-600">Fork me on GitHub!</a></small></footer>
        </aside>
      </div>
    </div>
    """
  end

  def handle_event("query_preflight", unsigned_params, socket) do
    # TODO: Interests can be searched by "#"
    # Users can be searched by "@"
    query = get_in(unsigned_params, ~w(search entry))

    socket =
      case String.first(query) do
        "@" ->
          tail = String.replace_leading(query, "@", "")

          case Handle128.convert(tail) do
            {:ok, handle} ->
              socket
              |> assign(
                :trend_search_status,
                "Searching for user @" <> handle <> " returned unimplemented."
              )

            :error ->
              socket
              |> assign(
                :trend_search_status,
                "Invalid user search query."
              )
          end

        "#" ->
          tail = String.replace_leading(query, "#", "")

          case Handle128.convert(tail) do
            {:ok, handle} ->
              socket
              |> assign(
                :trend_search_status,
                "Searching for interest #" <> handle <> " returned unimplemented."
              )

            :error ->
              socket
              |> assign(
                :trend_search_status,
                "Invalid interest search query."
              )
          end

        id when not is_nil(id) ->
          socket
          |> assign(:trend_search_status, "Searching for " <> query <> " returned unimplemented.")

        nil ->
          socket
          |> assign(:trend_search_status, "Please enter your query.")
      end

    {:noreply, socket}
  end

  def handle_event("query_submit", unsigned_params, socket) do
    # TODO: Interests can be searched by "#"
    # Users can be searched by "@"

    query = get_in(unsigned_params, ~w(search entry))

    socket =
      case String.first(query) do
        "@" ->
          tail = String.replace_leading(query, "@", "")

          case Handle128.convert_nopadding(tail) do
            {:ok, handle} ->
              socket |> push_redirect(to: Routes.live_path(socket, ExsemanticaWeb.UserLive, handle))

            :error ->
              socket
              |> assign(
                :trend_search_status,
                "Invalid user search query."
              )
          end

        "#" ->
          tail = String.replace_leading(query, "#", "")

          case Handle128.convert_nopadding(tail) do
            {:ok, handle} ->
              socket |> push_patch(to: Routes.live_path(socket, InterestLive, handle))


            :error ->
              socket
              |> assign(
                :trend_search_status,
                "Invalid interest search query."
              )
          end

        id when not is_nil(id) ->
          socket
          |> assign(:trend_search_status, "Searching for " <> query <> " returned unimplemented.")

        nil ->
          socket
          |> assign(:trend_search_status, "Please enter your query.")
      end


    {:noreply, socket}
  end
end
