defmodule Exsemantica.IRC.ChannelStore do
  @moduledoc """
  Stores user processes residing in channels into a Mnesia database.

  Since Mnesia in RAM is more decoupled than ETS, which terminates when the heir
  terminates, we have decided to use Mnesia for now.

  TODO: Should we use a different database to cache users?
  """
  use GenServer

  require Logger

  import Ecto.Query

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: {:global, __MODULE__})
  end

  def join(user_id, channel) do
    GenServer.call({:global, __MODULE__}, {:join, user_id, channel})
  end

  def part(user_id, channel, reason) do
    GenServer.call({:global, __MODULE__}, {:part, user_id, channel, reason})
  end

  def disconnect(user_id, reason) do
    GenServer.cast({:global, __MODULE__}, {:disconnect, user_id, reason})
  end

  # ===========================================================================
  @impl GenServer
  def init(_args) do
    :mnesia.create_schema([node()])

    {:atomic, :ok} =
      :mnesia.create_table(__MODULE__.Entry,
        ram_copies: [node()],
        attributes: [:channel_name, :users],
        type: :set
      )

    {:ok, []}
  end

  @impl GenServer
  def handle_call({:join, id, channel = "#" <> aggregate}, from, state) do
    data =
      Exsemantica.Repo.one(
        from a in Exsemantica.Repo.Aggregate,
          where: ilike(a.name, ^aggregate),
          select: a,
          preload: [:bans, :moderators]
      )

    reply =
      case data do
        nil ->
          {:error, {:no_such_channel, channel}}

        real_data = %Exsemantica.Repo.Aggregate{name: name, hidden?: true, hidden_reason: reason} ->
          {:error, {:hidden, "#" <> name, reason}}

        real_data ->
          {id, real_data}
          # banned from this aggregate?
          |> check_if_banned()
          # is already in the channel?
          |> check_if_present()
          # too many non-moderators?
          |> check_if_excess()
          # finally join
          |> try_join(from)
      end

    {:reply, reply, state}
  end

  @impl GenServer
  def handle_call({:part, id, channel = "#" <> aggregate, reason}, from, state) do
    data =
      Exsemantica.Repo.one(
        from a in Exsemantica.Repo.Aggregate,
          where: ilike(a.name, ^aggregate),
          select: a
      )

    reply =
      case data do
        nil ->
          {:error, {:no_such_channel, channel}}

        real_data ->
          {id, real_data, reason}
          # only need to check if not in channel
          |> check_if_not_present()
          # finally leave
          |> try_part(from)
      end

    {:reply, reply, state}
  end

  @impl GenServer
  def handle_cast({:disconnect, id, reason}, state) do
    {:atomic, processes} =
      :mnesia.transaction(fn ->
        # FIXME: Make this more efficient?
        # get all channels the ID is in
        channels =
          :mnesia.foldl(
            fn {__MODULE__.Entry, channel_name, users}, accumulator ->
              do_notify =
                users
                |> Enum.any?(fn {other_id, _misc_data} ->
                  id == other_id
                end)

              if do_notify do
                [channel_name | accumulator]
              else
                accumulator
              end
            end,
            [],
            __MODULE__.Entry
          )

        # get all user processess to notify
        processes =
          :mnesia.foldl(
            fn {__MODULE__.Entry, channel_name, users}, accumulator ->
              if channel_name in channels do
                {user_ids, misc_infos} = users |> Enum.unzip()

                processes = misc_infos |> Enum.map(& &1.user_process)

                accumulator |> MapSet.union(MapSet.new(processes))
              else
                accumulator
              end
            end,
            MapSet.new(),
            __MODULE__.Entry
          )

        processes
      end)

    quitter = Exsemantica.Repo.one(Exsemantica.Repo.User, id: id)

    for process <- processes do
      send(process, {:user_disconnected, quitter, reason})
    end

    {:noreply, state}
  end

  # ===========================================================================
  defp check_if_banned({user_id, aggregate = %Exsemantica.Repo.Aggregate{name: name, bans: bans}}) do
    filtered_bans =
      bans
      |> Enum.filter(fn %Exsemantica.Repo.Aggregate.Ban{user_id: banned_id, expire: expiry} ->
        user_id == banned_id and DateTime.after?(expiry, DateTime.utc_now())
      end)

    case filtered_bans do
      [] ->
        {:ok, user_id, aggregate}

      [%Exsemantica.Repo.Aggregate.Ban{reason: reason, expire: expiry} | _] ->
        {:error, {:banned, "#" <> name, expiry, reason}}
    end
  end

  defp check_if_present({:ok, user_id, aggregate = %Exsemantica.Repo.Aggregate{name: name}}) do
    response =
      :mnesia.transaction(fn ->
        q = :mnesia.read(__MODULE__.Entry, name)

        if q != [] do
          [{__MODULE__.Entry, _name, users}] = q

          users
          |> Enum.all?(fn {other_id, _misc_data} ->
            user_id != other_id
          end)
        else
          # Initializes a new channel cache
          :mnesia.write({__MODULE__.Entry, name, []})
          true
        end
      end)

    case response do
      {:atomic, true} ->
        {:ok, user_id, aggregate}

      {:atomic, false} ->
        {:error, {:already_present, "#" <> name}}
    end
  end

  defp check_if_present(response = {:error, _error}) do
    response
  end

  defp check_if_excess(
         {:ok, user_id,
          aggregate = %Exsemantica.Repo.Aggregate{
            name: name,
            chat_limit: limit,
            moderators: moderators
          }}
       ) do
    moderator? =
      moderators
      |> Enum.any?(fn %Exsemantica.Repo.User{id: id} ->
        user_id == id
      end)

    response =
      :mnesia.transaction(fn ->
        users = :mnesia.read(__MODULE__.Entry, name)

        length(users) <= limit or moderator?
      end)

    case response do
      {:atomic, true} ->
        {:ok, user_id, aggregate, moderator?}

      {:atomic, false} ->
        {:error, {:too_many_users, "#" <> name}}
    end
  end

  defp check_if_excess(response = {:error, _error}) do
    response
  end

  defp try_join(
         {:ok, user_id,
          aggregate = %Exsemantica.Repo.Aggregate{
            name: name,
            description: description,
            description_modified: modified
          }, moderator?},
         from
       ) do
    {:atomic, previous_users} =
      :mnesia.transaction(fn ->
        q = :mnesia.read(__MODULE__.Entry, name)

        users = if q != [] do
          [{__MODULE__.Entry, _name, users}] = q
          users
        else
          []
        end

        :mnesia.write(
          {__MODULE__.Entry, name,
           [{user_id, %{moderator?: moderator?, user_process: from}} | users]}
        )

        users
      end)

    joiner = Exsemantica.Repo.one(Exsemantica.Repo.User, id: user_id)

    for {_user_id, %{user_process: user_process}} <- previous_users do
      send(user_process, {:user_joined, joiner, name})
    end

    users_moderators = previous_users |> Enum.map(fn {_, _, u} -> u end) |> Map.new()
    user_ids = users_moderators |> Map.keys()

    users_queried =
      Exsemantica.Repo.all(
        from u in Exsemantica.Repo.User,
          where: u.id in ^user_ids,
          select: %{id: u.id, username: u.username}
      )

    user_list =
      users_queried
      |> Enum.map(fn %{id: user_queried_id, username: username} ->
        if get_in(users_moderators, [user_queried_id]) do
          "@" <> username
        else
          username
        end
      end)

    {:ok, {:joined, aggregate, ["~Services" | user_list]}}
  end

  defp try_join(response = {:error, _error}, _from) do
    response
  end

  defp check_if_not_present(
         {user_id, aggregate = %Exsemantica.Repo.Aggregate{name: name}, reason}
       ) do
    response =
      :mnesia.transaction(fn ->
        q = :mnesia.read(__MODULE__.Entry, name)

        if q == [] do
          false
        else
          [{__MODULE__.Entry, _name, users}] = q
          users
          |> Enum.any?(fn {other_id, _misc_data} ->
            user_id == other_id
          end)
        end
      end)

    case response do
      {:atomic, true} ->
        {:ok, user_id, aggregate, reason}

      {:atomic, false} ->
        {:error, {:already_not_present, "#" <> name}}
    end
  end

  defp try_part({:ok, user_id, aggregate = %Exsemantica.Repo.Aggregate{name: name}, reason}, from) do
    {:atomic, next_users} =
      :mnesia.transaction(fn ->
        # FIXME: Make this more efficient?
        q = :mnesia.read(__MODULE__.Entry, name)

        users = if q != [] do
          [{__MODULE__.Entry, _name, users}] = q

          users
          |> Enum.reject(fn {other_id, _misc_data} ->
            user_id == other_id
          end)
        else
          []
        end

        :mnesia.write({__MODULE__.Entry, name, users})

        users
      end)

    parter = Exsemantica.Repo.one(Exsemantica.Repo.User, id: user_id)

    for {_user_id, %{user_process: user_process}} <- next_users do
      send(user_process, {:user_parted, parter, name, reason})
    end

    {:ok, {:parted, aggregate}}
  end

  defp try_part(response = {:error, _error}, _from) do
    response
  end
end
