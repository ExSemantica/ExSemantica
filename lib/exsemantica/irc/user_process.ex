defmodule Exsemantica.IRC.UserProcess do
  @moduledoc """
  Handles chat commands and keeping.

  This is for users on Phoenix and IRC.
  """
  use GenServer, restart: :temporary

  require Logger

  @ping_timeout_milliseconds 5000
  @ping_milliseconds 60000 - @ping_timeout_milliseconds

  def start_link(args = %{id: id}) do
    GenServer.start_link(__MODULE__, args, name: {:global, {__MODULE__, id}})
  end

  @impl true
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

  @impl true
  def handle_info(:welcome_burst, state = %{connection: {:tcp, tcp_pid}}) do
    [1, 2, 3, 4, 5, 251, 255, 375, 372, 376]
    |> Enum.map(&Exsemantica.IRC.Numerics.handle(state, &1))
    |> List.flatten()
    |> Enum.map(&send(tcp_pid, {:send_message, &1}))

    {:noreply, state}
  end

  @impl true
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

  @impl true
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

  @impl true
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

  @impl true
  def handle_info(:tcp_do_timeout, state = %{connection: {:tcp, tcp_pid}, last_ping: last_ping}) do
    timed_out_at = DateTime.utc_now() |> DateTime.to_unix()
    timed_out = ["Ping timeout: ", (timed_out_at - last_ping) |> to_string(), " seconds"]

    send(
      tcp_pid,
      {:send_message,
       %Exsemantica.IRC.Message{
         command: "ERROR",
         trailing: Exsemantica.IRC.Message.encode_quit_reason(timed_out)
       }}
    )

    {:stop, :normal, state}
  end

  @impl true
  def handle_info({:recv_message, malformed}, state) do
    Logger.debug("Malformed message received", irc_data: malformed)

    {:noreply, state}
  end
end
