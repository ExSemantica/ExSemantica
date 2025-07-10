defmodule ExsemanticaWeb.ChatChannel do
  @moduledoc """
  Handles chat messages.

  See [the IRCv3 docs](https://modern.ircdocs.horse) for more information on
  the numeric mappings.
  """
  use ExsemanticaWeb, :channel

  @impl true
  def join("chat:control", _payload, socket) do
    # This contains the `Exsemantica.Repo.User` data that we set before.
    user = socket.assigns.chat_user

    cond do
      user.banned? ->
        # Send an expiry date to the user. Bans can be permanent too.
        expire =
          if is_nil(user.banned_expire) do
            "No expiry set"
          else
            user.banned_expire |> DateTime.to_string()
          end

        {:error,
         %{
           reason: "You are banned (reason: #{user.banned_reason}) (expires: #{expire})",
           irc_compat: %{
             source: ExsemanticaWeb.Endpoint.host(),
             client: user.username,
             numerics: [:ERR_YOUREBANNEDCREEP]
           }
         }}

      length(ExsemanticaWeb.ChatPresence.list("chat:user_#{user.id}")) > 0 ->
        {:error,
         %{
           reason: "This account is already logged in to chat",
           irc_compat: %{
             source: ExsemanticaWeb.Endpoint.host(),
             client: user.username,
             numerics: [:ERR_NICKNAMEINUSE]
           }
         }}

      true ->
        # TODO: For Presence metadata, what IRC data can we track...
        ExsemanticaWeb.ChatPresence.track(socket, user.id, %{})

        {:ok,
         %{
           irc_compat: %{
             source: ExsemanticaWeb.Endpoint.host(),
             client: user.username,
             server_version: Application.spec(:exsemantica, :vsn),
             server_created:
               Exsemantica.ApplicationInfo.get_last_refreshed() |> DateTime.to_string(),
             numerics: [
               :RPL_WELCOME,
               :RPL_YOURHOST,
               :RPL_CREATED,
               :RPL_MYINFO,
               :RPL_ISUPPORT,
               :RPL_MOTDSTART,
               :RPL_MOTD,
               :RPL_ENDOFMOTD
             ]
           }
         }, socket}
    end
  end

  # Channels can be used in a request/response fashion
  # by sending replies to requests from the client
  @impl true
  def handle_in("ping", payload, socket) do
    {:reply, {:ok, payload}, socket}
  end

  # It is also common to receive messages from the client and
  # broadcast to everyone in the current topic (chat:lobby).
  @impl true
  def handle_in("shout", payload, socket) do
    broadcast(socket, "shout", payload)
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(_payload) do
    true
  end

  defp state_to_irc(%{numerics: numerics} = irc_compat) do
    numerics
    # We need to parse the numerics, then make the multiline numeric results
    # into one flat multiline document
    # |> Enum.flat_map(fn c -> Exsemantica.IRC.Bridging.handle(&1, c) |> IO.iodata_to_binary() end)

    # After this it is up to the server to send these one line at a time!
  end
end
