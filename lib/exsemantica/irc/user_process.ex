defmodule Exsemantica.IRC.UserProcess do
  @moduledoc """
  Handles chat commands and keeping.

  This is for users on Phoenix and IRC.
  """
  use GenServer, restart: :temporary

  require Logger

  @ping_timeout_milliseconds 5_000
  @ping_milliseconds 60_000 - @ping_timeout_milliseconds

  @doc """
  Starts this process given a user ID in the users table, their handle, and
  socket tuple.

  TODO: Make the "socket tuple" better documented.
  """
  def start_link(args = %{id: id}) do
    GenServer.start_link(__MODULE__, args, name: {:global, {__MODULE__, id}})
  end

  def force_disconnect(id, reason) do
    GenServer.cast({:global, {__MODULE__, id}}, {:force_disconnect, reason})
  end

  # ===========================================================================

  @impl GenServer
  def handle_cast({:force_disconnect, reason}, state) do
    killed = ["Killed (", reason, ")"]

    send(self(), {:disconnect, killed})

    {:noreply, state}
  end

  # ===========================================================================

  @impl GenServer
  def init(process_args = %{id: id, handle: handle, connection: connection}) do
    case connection do
      {:tcp, tcp_pid} ->
        Logger.debug("User process spawned (TCP)", process_args: process_args)
        Process.link(tcp_pid)

        state = %{
          id: id,
          nickname: handle,
          connection: connection,
          ping: Process.send_after(self(), :tcp_send_ping, @ping_milliseconds),
          last_ping: DateTime.utc_now() |> DateTime.to_unix(),
          last_ping_token: nil,
          timeout: nil
        }

        # HACK: bypass race condition with Supervisor.count_children
        send(self(), :welcome_burst)

        {:ok, state}
    end
  end

  @impl GenServer
  def handle_info(:welcome_burst, state = %{connection: {:tcp, tcp_pid}}) do
    numerics =
      [1, 2, 3, 4, 5, 251, 255, 375, 372, 376]
      |> Enum.map(&Exsemantica.IRC.Numerics.handle(state, &1))
      |> List.flatten()

    for numeric <- numerics do
      send(tcp_pid, {:send_message, numeric})
    end

    {:noreply, state}
  end

  @impl GenServer
  def handle_info(:tcp_send_ping, state = %{connection: {:tcp, tcp_pid}}) do
    token =
      ["T", DateTime.utc_now() |> DateTime.to_unix() |> to_string()] |> IO.iodata_to_binary()

    send(
      tcp_pid,
      {:send_message,
       %Exsemantica.IRC.Message{
         prefix: ExsemanticaWeb.Endpoint.host(),
         command: "PING",
         params: [token]
       }}
    )

    {:noreply,
     %{
       state
       | timeout: Process.send_after(self(), :tcp_do_timeout, @ping_timeout_milliseconds),
         last_ping_token: token
     }}
  end

  @impl GenServer
  def handle_info(
        {:recv_message, %Exsemantica.IRC.Message{command: "PING", params: [token]}},
        state = %{connection: {:tcp, tcp_pid}}
      ) do
    source = ExsemanticaWeb.Endpoint.host()

    send(
      tcp_pid,
      {:send_message,
       %Exsemantica.IRC.Message{
         prefix: source,
         command: "PONG",
         params: [source, token]
       }}
    )

    {:noreply, state}
  end

  @impl GenServer
  def handle_info(
        {:recv_message, %Exsemantica.IRC.Message{command: "PONG", params: [token]}},
        state = %{ping: ping, timeout: timeout, last_ping_token: token_last}
      )
      when token == token_last do
    Process.cancel_timer(ping)
    Process.cancel_timer(timeout)

    {:noreply,
     %{
       state
       | ping: Process.send_after(self(), :tcp_send_ping, @ping_milliseconds),
         last_ping: DateTime.utc_now() |> DateTime.to_unix(),
         last_ping_token: nil
     }}
  end

  @impl GenServer
  def handle_info(
        {:recv_message, %Exsemantica.IRC.Message{command: "JOIN", params: [which]}},
        state = %{id: id, nickname: nickname, connection: {:tcp, tcp_pid}}
      ) do
    channels = which |> String.split(",")

    for channel <- channels do
      response = Exsemantica.IRC.ChannelStore.join(id, channel)

      case response do
        # TODO: Display expiry
        {:error, {:banned, channel_name, _expiry, reason}} ->
          send(
            tcp_pid,
            {:send_message,
             Exsemantica.IRC.Numerics.handle(
               %{state | channel: channel_name, reason: reason},
               474
             )}
          )

        {:error, {:already_present, channel_name}} ->
          :dont_care

        {:error, {:too_many_users, channel_name}} ->
          send(
            tcp_pid,
            {:send_message,
             Exsemantica.IRC.Numerics.handle(%{state | channel: channel_name}, 471)}
          )

        {:ok,
         {:joined,
          %Exsemantica.Repo.Aggregate{name: name, description: topic, description_modified: date},
          users}} ->
          send(
            tcp_pid,
            {:send_message,
             %Exsemantica.IRC.Message{
               prefix: ExsemanticaWeb.Endpoint.host(),
               command: "JOIN",
               params: [nickname, "#" <> name]
             }}
          )

          numerics =
            [332, 333, 353, 366]
            |> Enum.map(
              &Exsemantica.IRC.Numerics.handle(
                state
                |> Map.merge(%{channel: "#" <> name, topic: topic, date: date, users: users}),
                &1
              )
            )
            |> List.flatten()

          for numeric <- numerics do
            send(tcp_pid, {:send_message, numeric})
          end
      end
    end

    {:noreply, state}
  end

  @impl GenServer
  def handle_info(
        {:recv_message,
         %Exsemantica.IRC.Message{command: "PART", params: [which], trailing: reason}},
        state = %{id: id, nickname: nickname, connection: {:tcp, tcp_pid}}
      ) do
    channels = which |> String.split(",")

    for channel <- channels do
      response = Exsemantica.IRC.ChannelStore.part(id, channel, reason)

      case response do
        {:error, {:already_not_present, channel_name}} ->
          send(
            tcp_pid,
            {:send_message,
             Exsemantica.IRC.Numerics.handle(
               %{state | channel: channel_name},
               442
             )}
          )

        {:ok, {:parted, %Exsemantica.Repo.Aggregate{name: name}}} ->
          send(
            tcp_pid,
            {:send_message,
             %Exsemantica.IRC.Message{
               prefix: ExsemanticaWeb.Endpoint.host(),
               command: "PART",
               params: [nickname, "#" <> name],
               trailing: reason
             }}
          )
      end
    end

    {:noreply, state}
  end

  @impl GenServer
  def handle_info(:tcp_do_timeout, state = %{last_ping: last_ping}) do
    timed_out_at = DateTime.utc_now() |> DateTime.to_unix()
    timed_out = ["Ping timeout: ", (timed_out_at - last_ping) |> to_string(), " seconds"]

    send(self(), {:disconnect, timed_out})

    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:recv_message, malformed}, state) do
    Logger.debug("Malformed message received", irc_data: malformed)

    {:noreply, state}
  end

  @impl GenServer
  def handle_info({:disconnect, reason}, state = %{id: id, connection: {:tcp, tcp_pid}}) do
    send(
      tcp_pid,
      {:send_message,
       %Exsemantica.IRC.Message{
         command: "ERROR",
         trailing: Exsemantica.IRC.Message.encode_quit_reason(reason)
       }}
    )

    Exsemantica.IRC.ChannelStore.disconnect(id, reason)

    Logger.debug("User process disconnected (TCP) (#{reason})")

    {:stop, :normal, state}
  end
end
