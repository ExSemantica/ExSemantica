defmodule Exsemantica.IRC.Handler do
  @moduledoc """
  TCP connection handling for raw IRC connections
  """
  use ThousandIsland.Handler

  # ===========================================================================
  # Constants that might change upon preference hot reloading
  # ===========================================================================
  @doc """
  Gets the time we wait for authentication.
  """
  def get_timeout_milliseconds(), do: 10000

  @doc """
  Gets the IRCv3 capabilities we only support here.
  """
  def get_gateway_capabilities(), do: MapSet.new(["sasl"])

  # ===========================================================================
  # Connection and data handling
  # ===========================================================================
  @impl ThousandIsland.Handler
  def handle_connection(_socket, _state) do
    {:continue, %Exsemantica.IRC.User{state: :wait_for_capabilities},
     {:persistent, get_timeout_milliseconds()}}
  end

  @impl ThousandIsland.Handler
  def handle_data(data, socket, state) do
    data
    |> Exsemantica.IRC.Message.decode()
    |> Stream.each(fn decoded -> send(self(), {:irc_message, decoded}) end)
    |> Stream.run()

    {:continue, state, socket.read_timeout}
  end

  # ===========================================================================
  # Pre-authentication packet(s) handling
  # ===========================================================================
  @impl GenServer
  def handle_info(
        {:irc_message, msg = %Exsemantica.IRC.Message{command: "CAP"}},
        {socket, state = %Exsemantica.IRC.User{}}
      ) do
    case msg.params do
      ["LS"] ->
        send_capabilities_ls(socket)

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
        send_capabilities_ls(socket)

        {:noreply, {socket, state}, socket.read_timeout}

      ["REQ"] ->
        :unimplemented

      ["END"] ->
        :unimplemented
    end
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
  defp change_capabilities(socket, state, capabilities_string) do
    capabilities =
      capabilities_string
      |> String.split(" ")

    capabilities_removed =
      capabilities |> Enum.filter(fn c -> String.starts_with?(c, "-") end)

    capabilities_added =
      capabilities |> Enum.reject(fn c -> String.starts_with?(c, "-") end)

    capabilities =
      MapSet.new(capabilities_added)
      |> MapSet.intersection(get_gateway_capabilities())
      |> MapSet.difference(capabilities_removed)
  end

  defp end_capabilities(socket, state) do
  end

  defp send_capabilities_ls(socket) do
    socket
    |> send_struct(%Exsemantica.IRC.Message{
      command: "CAP",
      params: ["*", "LS"],
      trailing: get_gateway_capabilities() |> MapSet.to_list() |> Enum.intersperse(" ")
    })
  end

  defp send_struct(socket, message_struct) do
    # Encode the structure into an iolist then a binary
    packet = message_struct |> Exsemantica.IRC.Message.encode() |> IO.iodata_to_binary()

    # Send the binary to our client
    ThousandIsland.Socket.send(socket, packet)
  end
end
