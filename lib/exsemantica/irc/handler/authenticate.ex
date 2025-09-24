defmodule Exsemantica.IRC.Handler.Authenticate do
  @moduledoc """
  Handle IRCv3 AUTHENTICATE messages (SASL)
  """

  @doc """
  Called by `Exsemantica.IRC.Handler`
  """
  def handle(
        msg,
        {socket, state = %Exsemantica.IRC.User{state: user_state, capabilities: capabilities}}
      ) do
    has_sasl? = MapSet.member?(capabilities, "sasl")
    handle_params({socket, state}, msg.params, has_sasl?, user_state)
  end

  # ===========================================================================
  defp handle_params({socket, state}, ["*"], true, :sasl_streaming) do
    for packet <- Exsemantica.IRC.Numerics.handle(state, 906) do
      socket
      |> Exsemantica.IRC.Handler.send_struct(packet)
    end

    {:noreply, {socket, %Exsemantica.IRC.User{state | state: :wait_for_capabilities}},
     socket.read_timeout}
  end

  defp handle_params({socket, state}, ["PLAIN"], true, :wait_for_capabilities) do
    socket
    |> Exsemantica.IRC.Handler.send_struct(%Exsemantica.IRC.Message{
      command: "AUTHENTICATE",
      params: ["+"]
    })

    {:noreply, {socket, %Exsemantica.IRC.User{state | state: :sasl_streaming}},
     socket.read_timeout}
  end

  defp handle_params({socket, state}, ["+"], true, :sasl_streaming) do
    check_sasl_data(socket, state, {:ok, ""})
  end

  defp handle_params({socket, state}, [data], true, :sasl_streaming) do
    check_sasl_data(socket, state, Base.decode64(data))
  end

  defp handle_params({socket, state}, [_bogus_mechanism], true, :wait_for_capabilities) do
    for packet <- Exsemantica.IRC.Numerics.handle(state, 908) do
      socket
      |> Exsemantica.IRC.Handler.send_struct(packet)
    end

    {:noreply, {socket, state}, socket.read_timeout}
  end

  defp handle_params({socket, state}, _already_authenticated, true, :connected) do
    for packet <- Exsemantica.IRC.Numerics.handle(state, 907) do
      socket
      |> Exsemantica.IRC.Handler.send_struct(packet)
    end

    {:noreply, {socket, state}, socket.read_timeout}
  end

  # All other params are bogus and should be ignored (let it crash)
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
          |> Exsemantica.IRC.Handler.send_struct(packet)
        end

        for packet <- Exsemantica.IRC.Numerics.handle(state, 903) do
          socket
          |> Exsemantica.IRC.Handler.send_struct(packet)
        end

        {:noreply, {socket, state}, socket.read_timeout}

      {:error, ban = {:banned, _reason, _expiry}} ->
        socket
        |> Exsemantica.IRC.Handler.send_struct(%Exsemantica.IRC.Message{
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
          |> Exsemantica.IRC.Handler.send_struct(packet)
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
      |> Exsemantica.IRC.Handler.send_struct(packet)
    end

    {:noreply, {socket, state}, socket.read_timeout}
  end

  defp check_sasl_data(socket, state = %Exsemantica.IRC.User{}, _) do
    state = %Exsemantica.IRC.User{state | sasl_data: []}

    for packet <- Exsemantica.IRC.Numerics.handle(state, 904) do
      socket
      |> Exsemantica.IRC.Handler.send_struct(packet)
    end

    {:noreply, {socket, state}, socket.read_timeout}
  end
end
