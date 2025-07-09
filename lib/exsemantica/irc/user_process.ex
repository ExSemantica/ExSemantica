defmodule Exsemantica.IRC.UserProcess do
  @moduledoc """
  Handles chat commands and keeping.

  This is for users on Phoenix and IRC.
  """
  use GenServer, restart: :temporary

  def start_link(args = %{handle: handle}) do
    GenServer.start_link(__MODULE__, args, name: {:global, {__MODULE__, handle}})
  end

  def init(%{handle: handle}) do
    {:ok, %{handle: handle}}
  end
end
