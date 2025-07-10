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
  def get_timeout_milliseconds(), do: 5000

  @doc """
  Gets the IRCv3 capabilities we only support here.
  """
  def get_gateway_capabilities(), do: MapSet.new(["sasl"])

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
  def handle_info({:send_message, msg}, {socket, state = %Exsemantica.IRC.User{state: :connected}}) do
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
  # Pre-authentication packet(s) handling
  # ===========================================================================
  @impl GenServer
  def handle_info(
        {:recv_message, msg = %Exsemantica.IRC.Message{command: "CAP"}},
        {socket, state = %Exsemantica.IRC.User{id: id}}
      ) do
    case msg.params do
      ["LS"] ->
        send_capabilities_ls(socket, state)

        {:noreply, {socket, state}, socket.read_timeout}

      ["LS", raw_version] ->
        {version, _} = Integer.parse(raw_version)

        # Update the capability version if higher than stored
        state =
          if is_nil(state.capability_version) or raw_version > state.capability_version do
            %Exsemantica.IRC.User{state | capability_version: version}
          else
            state
          end

        # In case the backend updates above capability version 302 or something else
        send_capabilities_ls(socket, state)

        {:noreply, {socket, state}, socket.read_timeout}

      ["REQ"] ->
        state = change_capabilities(socket, state, msg.trailing)

        {:noreply, {socket, state}, socket.read_timeout}

      ["END"] when not is_nil(id) ->
        spawn_user_process(socket, state)

      ["END"] ->
        # It is perfectly fine otherwise if the user isn't logged in.
        {:noreply, {socket, state}, socket.read_timeout}
    end
  end

  @impl GenServer
  def handle_info(
        {:recv_message, msg = %Exsemantica.IRC.Message{command: "AUTHENTICATE"}},
        {socket, state = %Exsemantica.IRC.User{state: user_state, capabilities: capabilties}}
      ) do
    has_sasl? = MapSet.member?(capabilties, "sasl")

    case msg.params do
      ["*"] when has_sasl? and user_state == :sasl_streaming ->
        for packet <- Exsemantica.IRC.Numerics.handle(state, 906) do
          socket
          |> send_struct(packet)
        end

        {:noreply, {socket, %Exsemantica.IRC.User{state | state: :wait_for_capabilities}},
         socket.read_timeout}

      ["PLAIN"] when has_sasl? and user_state == :wait_for_capabilities ->
        socket
        |> send_struct(%Exsemantica.IRC.Message{command: "AUTHENTICATE", params: ["+"]})

        {:noreply, {socket, %Exsemantica.IRC.User{state | state: :sasl_streaming}},
         socket.read_timeout}

      ["+"] when has_sasl? and user_state == :sasl_streaming ->
        check_sasl_data(socket, state, {:ok, ""})

      [data] when has_sasl? and user_state == :sasl_streaming ->
        check_sasl_data(socket, state, Base.decode64(data))

      [_bogus_mechanism] when has_sasl? and user_state == :wait_for_capabilities ->
        for packet <- Exsemantica.IRC.Numerics.handle(state, 908) do
          socket
          |> send_struct(packet)
        end

        {:noreply, {socket, state}, socket.read_timeout}

      _already_in when has_sasl? and user_state == :connected ->
        for packet <- Exsemantica.IRC.Numerics.handle(state, 907) do
          socket
          |> send_struct(packet)
        end

        {:noreply, {socket, state}, socket.read_timeout}

      _bogus ->
        {:noreply, {socket, state}, socket.read_timeout}
    end
  end

  @impl GenServer
  def handle_info({:recv_message, %Exsemantica.IRC.Message{command: command}}, {socket, state})
      when command in ["NICK", "USER", "PASS"] do
    {:noreply, {socket, state}, socket.read_timeout}
  end

  @impl GenServer
  def handle_info(
        {:recv_message, what},
        {socket, state = %Exsemantica.IRC.User{state: :connected, user_process: process}}
      ) do
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
    socket
    |> send_struct(Exsemantica.IRC.Message.encode_shutdown())

    :ok
  end

  # ===========================================================================
  defp change_capabilities(
         socket,
         state = %Exsemantica.IRC.User{nickname: nickname, capabilities: old_capabilities},
         capabilities_string
       ) do
    capabilities =
      capabilities_string
      |> String.split(" ")

    capabilities_removed =
      capabilities
      |> Enum.filter(fn c -> String.starts_with?(c, "-") end)
      |> Enum.map(fn c -> String.replace_prefix(c, "-", "") end)
      |> MapSet.new()

    capabilities_added =
      capabilities
      |> Enum.reject(fn c -> String.starts_with?(c, "-") end)
      |> MapSet.new()

    new_capabilities_removed =
      old_capabilities
      |> MapSet.intersection(capabilities_removed)
      |> MapSet.intersection(get_gateway_capabilities())

    new_capabilities_removed_list =
      new_capabilities_removed
      |> MapSet.to_list()
      |> Enum.map(fn c -> ["-", c] end)
      |> Enum.intersperse(" ")

    new_capabilities_added =
      old_capabilities
      |> MapSet.union(capabilities_added)
      |> MapSet.intersection(get_gateway_capabilities())

    new_capabilities_added_list =
      new_capabilities_added |> MapSet.to_list() |> Enum.intersperse(" ")

    new_capabilities_list =
      case {new_capabilities_added_list, new_capabilities_removed_list} do
        {[], removed} ->
          removed

        {added, []} ->
          added

        {added, removed} ->
          [added, " ", removed]
      end

    if length(new_capabilities_list) > 0 do
      # This is a legal capability request
      socket
      |> send_struct(%Exsemantica.IRC.Message{
        prefix: ExsemanticaWeb.Endpoint.host(),
        command: "CAP",
        params: [nickname, "ACK"],
        trailing: new_capabilities_list
      })

      %Exsemantica.IRC.User{
        state
        | capabilities: new_capabilities_added |> MapSet.difference(new_capabilities_removed)
      }
    else
      # Resulting legal capabilities are empty so it should be declined
      socket
      |> send_struct(%Exsemantica.IRC.Message{
        prefix: ExsemanticaWeb.Endpoint.host(),
        command: "CAP",
        params: [nickname, "NAK"],
        trailing: capabilities_string
      })

      state
    end
  end

  defp send_capabilities_ls(socket, %Exsemantica.IRC.User{nickname: nickname}) do
    socket
    |> send_struct(%Exsemantica.IRC.Message{
      prefix: ExsemanticaWeb.Endpoint.host(),
      command: "CAP",
      params: [nickname, "LS"],
      trailing: get_gateway_capabilities() |> MapSet.to_list() |> Enum.intersperse(" ")
    })
  end

  # ===========================================================================

  defp check_sasl_data(socket, state = %Exsemantica.IRC.User{sasl_data: sasl_data}, {:ok, binary})
       when byte_size(binary) < 400 do
    full_data =
      [binary | sasl_data] |> Enum.reverse() |> Enum.join() |> String.split("\0")

    user_info =
      case full_data do
        [_authzid, authcid, password] ->
          Exsemantica.Authentication.check_user(authcid, password)

        _bad_sasl_data ->
          {:error, :bad_sasl_data}
      end

    case user_info do
      {:ok, %Exsemantica.Repo.User{id: id, username: username}} ->
        state = %Exsemantica.IRC.User{
          state
          | id: id,
            nickname: username,
            sasl_data: []
        }

        for packet <- Exsemantica.IRC.Numerics.handle(state, 900) do
          socket
          |> send_struct(packet)
        end

        for packet <- Exsemantica.IRC.Numerics.handle(state, 903) do
          socket
          |> send_struct(packet)
        end

        {:noreply, {socket, state}, socket.read_timeout}

      {:error, ban = {:banned, _reason, _expiry}} ->
        socket
        |> send_struct(%Exsemantica.IRC.Message{
          command: "ERROR",
          trailing:
            Exsemantica.IRC.Message.encode_quit_reason(
              Exsemantica.Authentication.get_user_error(ban)
            )
        })

        {:stop, :normal, {socket, state}}

      {:error, _error} ->
        state = %Exsemantica.IRC.User{state | sasl_data: []}

        for packet <- Exsemantica.IRC.Numerics.handle(state, 904) do
          socket
          |> send_struct(packet)
        end

        {:noreply, {socket, state}, socket.read_timeout}
    end
  end

  defp check_sasl_data(socket, state = %Exsemantica.IRC.User{sasl_data: sasl_data}, {:ok, binary})
       when byte_size(binary) == 400 do
    {:noreply, {socket, %Exsemantica.IRC.User{state | sasl_data: [binary | sasl_data]}},
     socket.read_timeout}
  end

  defp check_sasl_data(socket, state = %Exsemantica.IRC.User{}, {:ok, _}) do
    state = %Exsemantica.IRC.User{state | sasl_data: []}

    for packet <- Exsemantica.IRC.Numerics.handle(state, 905) do
      socket
      |> send_struct(packet)
    end

    {:noreply, {socket, state}, socket.read_timeout}
  end

  defp check_sasl_data(socket, state = %Exsemantica.IRC.User{}, _) do
    state = %Exsemantica.IRC.User{state | sasl_data: []}

    for packet <- Exsemantica.IRC.Numerics.handle(state, 904) do
      socket
      |> send_struct(packet)
    end

    {:noreply, {socket, state}, socket.read_timeout}
  end

  # ===========================================================================

  defp spawn_user_process(socket, state = %Exsemantica.IRC.User{id: id, nickname: nickname}) do
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

  defp send_struct(socket, message_struct) do
    # Encode the structure into an iolist then a binary
    packet = message_struct |> Exsemantica.IRC.Message.encode() |> IO.iodata_to_binary()

    # Send the binary to our client
    ThousandIsland.Socket.send(socket, packet)
  end
end
