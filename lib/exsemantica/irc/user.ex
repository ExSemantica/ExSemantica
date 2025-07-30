defmodule Exsemantica.IRC.User do
  @moduledoc """
  Structure to store connection/user data.
  """

  @enforce_keys [:id, :state, :nickname, :capabilities, :sasl_data]
  defstruct [:id, :state, :nickname, :capability_version, :capabilities, :sasl_data, :user_process]

  @doc """
  Gets the time-to-live of a chat account token.
  """
  def ttl_seconds(), do: 60 * 5

  @doc """
  Gets the maximum length of an IRC base36 ID.
  """
  def max_id36_len(), do: 16

  @doc """
  Constructs a hostmask iolist.
  """
  def construct_hostmask(%{id: id, nickname: nickname}) do
    id_mask = Integer.to_string(id, 36)

    # TODO: add more cloaks later, maybe
    [
      nickname,
      "!~",
      String.duplicate("0", max_id36_len() - byte_size(id_mask) - 1),
      id_mask,
      "@user/",
      nickname
    ]
  end
end
