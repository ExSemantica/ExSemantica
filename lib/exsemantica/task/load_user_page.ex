defmodule Exsemantica.Task.LoadUserPage do
  @moduledoc """
  A task that loads a user page's data
  """
  @fetches ~w(posts)a
  @max_posts_per_page 10
  @behaviour Exsemantica.Task
  import Ecto.Query

  @impl true
  def run(%{id: id, fetch?: wanted_fetches} = args) do
    data = Exsemantica.Repo.get(Exsemantica.Repo.User, id)

    case data do
      # Couldn't find the user
      nil ->
        :not_found

      # Load from the user
      user ->
        %{
          user: user,
          info:
            @fetches
            |> Enum.filter(fn match ->
              match in wanted_fetches
            end)
            |> Enum.map(fn fmatch -> fetch(fmatch, id, args) end)
            |> Map.new()
        }
    end
  end

  defp fetch(:posts, id, %{options: %{load_by: :newest, page: page} = options}) do
    all_count =
      Exsemantica.Repo.aggregate(
        from(p in Exsemantica.Repo.Post, where: p.user_id == ^id),
        :count
      )

    pages_total = div(all_count, @max_posts_per_page)
    offset = page * @max_posts_per_page
    preloads = Map.get(options, :preloads, [])

    posts =
      if pages_total >= page do
        user =
          Exsemantica.Repo.get(Exsemantica.Repo.User, id)
          |> Exsemantica.Repo.preload(
            posts:
              from(p in Exsemantica.Repo.Post,
                order_by: [desc: p.inserted_at],
                preload: ^[:user, :aggregate | preloads]
              )
          )

        user.posts
        |> Enum.slice(offset, @max_posts_per_page)
      else
        []
      end

    {:posts,
     %{
       contents: posts,
       pages_total: pages_total,
       pages_began?: page < 1,
       pages_ended?: page > pages_total - 1,
       votes:
         posts
         |> Enum.map(fn post ->
           {:ok, vote_count} = Exsemantica.Cache.fetch_vote({:post, post.id})
           {post.id, vote_count}
         end)
         |> Map.new()
     }}
  end
end
