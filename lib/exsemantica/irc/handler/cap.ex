defmodule Exsemantica.IRC.Handler.Cap do
  @moduledoc """
  Handle IRCv3 CAP messages (Capabilities)
  """

  @doc """
  Gets the IRCv3 capabilities that we only support
  """
  def get_capabilities(), do: MapSet.new(["sasl"])

  @doc """
  Called by `Exsemantica.IRC.Handler`
  """
  def handle(msg, {socket, state}) do
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

      ["END"] when not is_nil(state.id) ->
        Exsemantica.IRC.Handler.spawn_user_process(socket, state)
    end
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
      |> MapSet.intersection(get_capabilities())

    new_capabilities_removed_list =
      new_capabilities_removed
      |> MapSet.to_list()
      |> Enum.map(fn c -> ["-", c] end)
      |> Enum.intersperse(" ")

    new_capabilities_added =
      old_capabilities
      |> MapSet.union(capabilities_added)
      |> MapSet.intersection(get_capabilities())

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
      |> Exsemantica.IRC.Handler.send_struct(%Exsemantica.IRC.Message{
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
      |> Exsemantica.IRC.Handler.send_struct(%Exsemantica.IRC.Message{
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
    |> Exsemantica.IRC.Handler.send_struct(%Exsemantica.IRC.Message{
      prefix: ExsemanticaWeb.Endpoint.host(),
      command: "CAP",
      params: [nickname, "LS"],
      trailing: get_capabilities() |> MapSet.to_list() |> Enum.intersperse(" ")
    })
  end
end
