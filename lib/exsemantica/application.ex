defmodule Exsemantica.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    case Application.get_env(:exsemantica, :commit_sha_result) do
      {sha, 0} ->
        sha |> String.replace_trailing("\n", "")
          :persistent_term.put(Exsemantica.Version, "#{Application.spec(:exsemantica, :vsn)}-#{sha}")
        _ ->
          :persistent_term.put(Exsemantica.Version, Application.spec(:exsemantica, :vsn))
    end

    children = [
      # Start the Telemetry supervisor
      ExsemanticaWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Exsemantica.PubSub},
      # Start the Endpoints (http/https)
      ExsemanticaWeb.Endpoint,
      ExsemanticaWeb.EndpointApi,
      {Absinthe.Subscription, ExsemanticaWeb.EndpointApi},
      # Start Exsemnesia KV storage
      {Exsemnesia.Database,
       [
         tables: %{
           users: ~w(node timestamp handle privmask)a,
           posts: ~w(node timestamp handle title content posted_by)a,
           interests: ~w(node timestamp handle title content related_to)a,
           auth: ~w(handle hash state secret)a,
           counters: ~w(type count)a
         },
         caches: %{
           # This is weird. You can botch a composite key. Cool!
           ctrending: ~w(count_node node type htimestamp handle)a,
           lowercases: ~w(handle lowercase)a,
         },
         tcopts: %{
           extra_indexes: %{
             users: ~w(handle)a,
             posts: ~w(handle)a,
             interests: ~w(handle)a,
             ctrending: ~w(node)a,
             lowercases: ~w(lowercase)a
           },
           ordered_caches: ~w(ctrending)a,
           seed_trends: ~w(users posts interests)a,
           seed_seeder: fn entry ->
             {table, id, handle} =
               case entry do
                 {:users, id, _timestamp, handle, _privmask} ->
                   {:users, id, handle}

                 {:posts, id, _timestamp, handle, _title, _content, _posted_by} ->
                   {:posts, id, handle}

                 {:interests, id, _timestamp, handle, _title, _content, _related_to} ->
                   {:interests, id, handle}
               end

             :mnesia.write(
               :ctrending,
               {:ctrending, {0, id}, id, table, DateTime.utc_now(), handle},
               :sticky_write
             )

             :mnesia.write(
               :lowercases,
               {:lowercases, handle, String.downcase(handle, :ascii)},
               :sticky_write
             )
           end
         }
       ]},
       ExsemanticaWeb.AnnounceServer
      # Start a worker by calling: Exsemantica.Worker.start_link(arg)
      # {Exsemantica.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Exsemantica.Supervisor]
    reply = Supervisor.start_link(children, opts)

    Exsemnesia.Utils.shuffle_invite()

    reply
  end

  # Tell Phoenix to update the endpoint configurations
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    ExsemanticaWeb.Endpoint.config_change(changed, removed)
    ExsemanticaWeb.EndpointApi.config_change(changed, removed)
    :ok
  end
end