defmodule ExsemanticaWeb.PageLive do
  use ExsemanticaWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="justify-center w-screen">
    <div class="flex flex-row gap-8 m-16 items-start">
    <div class="basis-2/3">
    <header class="bg-indigo-400 rounded-lg drop-shadow-xl p-8">
    <h1 class="text-2xl">Welcome to ExSemantica!</h1>
    <p><i>A free and open source microblogging and messaging platform for people who share interests.</i></p>
    <br>
    <p>Check the sidebar to see what's popular. Check below for your interest feed.</p>
    </header>
    <div class="bg-indigo-300 rounded-lg drop-shadow-xl p-8 mt-8">
    <.live_component module={ExsemanticaWeb.SearchComponent} id={"search"} />
    </div>
    </div>
    <div class="basis-1/3">
    <div class="bg-indigo-300 rounded-lg drop-shadow-xl p-8">
    <input type="search" placeholder="🔍 Search..." class="bg-indigo-200 rounded-full w-full mb-4 p-1/4 drop-shadow-md">
    <br>
    <h2 class="text-xl"><i>Trending interests</i></h2>
    <div id="trending-items">
    </div>
    <br>
    <p class="text-xs"><i>Trends up-to-date as of <b><span id="trending-date">...</span></b></i></p>
    </div>
    <br>
    <footer class="text-xs text-center">ExSemantica v<%= Application.spec(:exsemantica, :vsn) %> - <a href="https://github.com/Chlorophytus/exsemantica" class="underline decoration-sky-600 text-sky-600">Fork me on GitHub!</a></footer>
    </div>
    </div>
    </div>
    """
  end
end
