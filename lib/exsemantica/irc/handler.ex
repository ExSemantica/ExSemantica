defmodule Exsemantica.IRC.Handler do
  @moduledoc """
  TCP connection handling for raw IRC connections

  NOTE: When state is `:connected`, timeout must be driven to `:infinity`.
  """
  use ThousandIsland.Handler

  # ===========================================================================
  # Constants that might change upon preference hot reloading
  # ===========================================================================
  @doc """
  Gets the time we wait for authentication.
  """
  def get_timeout_milliseconds(), do: 5_000

  # ===========================================================================
  # Connection and data handling
  # ===========================================================================
  @impl ThousandIsland.Handler
  def handle_connection(_socket, _state) do
    {:continue,
     %Exsemantica.IRC.User{
       id: nil,
       state: :wait_for_capabilities,
       nickname: "*",
       capabilities: MapSet.new(),
       sasl_data: []
     }, {:persistent, get_timeout_milliseconds()}}
  end

  @impl ThousandIsland.Handler
  def handle_data(data, socket, state) do
    data
    |> Exsemantica.IRC.Message.decode()
    |> Stream.each(fn decoded -> send(self(), {:recv_message, decoded}) end)
    |> Stream.run()

    {:continue, state, socket.read_timeout}
  end

  # ===========================================================================
  # Send packet(s) handling
  # ===========================================================================
  @impl GenServer
  def handle_info(
        {:send_message, msg},
        {socket, state = %Exsemantica.IRC.User{state: :connected}}
      ) do
    socket
    |> send_struct(msg)

    {:noreply, {socket, state}, :infinity}
  end

  @impl GenServer
  def handle_info({:send_message, msg}, {socket, state}) do
    socket
    |> send_struct(msg)

    {:noreply, {socket, state}, socket.read_timeout}
  end

  @impl GenServer
  def handle_info({:EXIT, _from, reason}, {socket, state}) do
    {:stop, reason, {socket, state}}
  end

  # ===========================================================================
  # IRCv3 packet(s) handling
  # ===========================================================================
  @impl GenServer
  def handle_info(
        {:recv_message, msg = %Exsemantica.IRC.Message{command: "CAP"}},
        {socket, state = %Exsemantica.IRC.User{id: id}}
      ) do
    __MODULE__.Cap.handle(msg, {socket, state})
  end

  @impl GenServer
  def handle_info(
        {:recv_message, msg = %Exsemantica.IRC.Message{command: "AUTHENTICATE"}},
        {socket, state}
      ) do
    __MODULE__.Authenticate.handle(msg, {socket, state})
  end

  @impl GenServer
  def handle_info(
        {:recv_message, msg = %Exsemantica.IRC.Message{command: "QUIT"}},
        {socket, state}
      ) do
    reason =
      if is_nil(msg.trailing) do
        ["Client Quit"]
      else
        ["Quit: ", msg.trailing]
      end

    if is_pid(state.user_process) and Process.alive?(state.user_process) do
      send(state.user_process, {:disconnect, reason})
    else
      socket
      |> send_struct(%Exsemantica.IRC.Message{
        command: "ERROR",
        trailing: Exsemantica.IRC.Message.encode_quit_reason(reason)
      })
    end

    {:stop, :normal, {socket, state}}
  end

  @impl GenServer
  def handle_info(
        {:recv_message, %Exsemantica.IRC.Message{command: command}},
        {socket, state = %Exsemantica.IRC.User{state: user_state}}
      )
      when command in ["NICK", "USER", "PASS"] and user_state != :connected do
    {:noreply, {socket, state}, socket.read_timeout}
  end

  @impl GenServer
  def handle_info(
        {:recv_message, what},
        {socket, state = %Exsemantica.IRC.User{state: :connected, user_process: process}}
      ) do
    # Delegate everything else to the user process
    send(process, {:recv_message, what})

    {:noreply, {socket, state}, :infinity}
  end

  # ===========================================================================
  # Termination handling
  # ===========================================================================
  @impl ThousandIsland.Handler
  def handle_timeout(socket, _state) do
    socket
    |> send_struct(Exsemantica.IRC.Message.encode_authentication_timeout())

    :ok
  end

  @impl ThousandIsland.Handler
  def handle_shutdown(socket, _state) do
    # This is called when `:init.stop()` is called
    socket
    |> send_struct(Exsemantica.IRC.Message.encode_shutdown())

    :ok
  end

  # ===========================================================================
  def send_struct(socket, message_struct) do
    # Encode the structure into an iolist then a binary
    packet = message_struct |> Exsemantica.IRC.Message.encode() |> IO.iodata_to_binary()

    # Send the binary to our client
    ThousandIsland.Socket.send(socket, packet)
  end

  def spawn_user_process(socket, state = %Exsemantica.IRC.User{id: id, nickname: nickname}) do
    case Exsemantica.IRC.UserSupervisor.start_child(%{
           id: id,
           handle: nickname,
           connection: {:tcp, self()}
         }) do
      {:ok, user_process} ->
        {:noreply,
         {socket, %Exsemantica.IRC.User{state | user_process: user_process, state: :connected}},
         :infinity}

      {:error, :max_children} ->
        socket
        |> send_struct(%Exsemantica.IRC.Message{
          command: "ERROR",
          trailing: Exsemantica.IRC.Message.encode_quit_reason("Too many users online")
        })

        {:stop, :normal, {socket, state}}

      {:error, {:already_started, _pid}} ->
        socket
        |> send_struct(%Exsemantica.IRC.Message{
          command: "ERROR",
          trailing: Exsemantica.IRC.Message.encode_quit_reason("You are already logged in")
        })

        {:stop, :normal, {socket, state}}
    end
  end
end
