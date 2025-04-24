defmodule ExsemanticaWeb.ChatPresence do
  @moduledoc """
  Handles user counts.

  Please look into `Phoenix.Presence` documentation for more information.
  """

  use Phoenix.Presence,
    otp_app: :exsemantica,
    pubsub_server: Exsemantica.PubSub
end
