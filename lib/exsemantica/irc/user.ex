defmodule Exsemantica.IRC.User do
  @moduledoc """
  Structure to store connection/user data.
  """

  @doc """
  Gets the time-to-live of a chat account token.
  """
  def get_ttl_seconds(), do: 60 * 5

  @enforce_keys [:state]
  defstruct [:id, :state, :capability_version]
end
