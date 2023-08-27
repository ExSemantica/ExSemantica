defmodule Exsemantica.HandleGuards do
  @moduledoc """
  Guards that apply to handles site-wide and IRCd-wide.
  """

  @doc """
  Checks if the character is valid.

  This is used to check validity of characters in different handles site-wide
  dnd IRCd-wide.

  Note the fact that this is a *subset* of valid RFC 2812 characters.
  """
  defguard is_valid_char(item) when item in 0x41..0x5A or item in 0x61..0x7A or item == 0x5F

  @doc """
  Preemptive criteria for an `AggHandle`, before character checks, etc.
  """
  defguard is_valid_agg_pre(item) when is_binary(item) and byte_size(item) > 0 and byte_size(item) <= 32

  @doc """
  Preemptive criteria for a `Handle128`, before character checks, etc.
  """
  defguard is_valid_pre(item) when is_binary(item) and byte_size(item) > 0 and byte_size(item) <= 16
end
