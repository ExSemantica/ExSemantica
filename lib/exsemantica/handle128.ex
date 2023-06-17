# >>> Handle128 type (16-char ASCII identifier)
# Copyright 2023 Roland Metivier <metivier.roland@chlorophyt.us>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
defmodule Exsemantica.Handle128 do
  @moduledoc """
  16-character ASCII identifier that can be tested with most SIMD engines
  """

  defguardp is_valid(item) when is_binary(item) and byte_size(item) > 0 and byte_size(item) <= 16

  # IRC-style RFC2812 checking of certain characters
  defguardp is_irc_letter(char) when char in 0x41..0x5A or char in 0x61..0x7A
  defguardp is_irc_special(char) when char in 0x5B..0x60 or char in 0x7B..0x7D
  defguardp is_irc_digit(char) when char in 0x30..0x39

  @doc """
  Converts a handle into a Handle128 with at most 16 characters.

  This also downcases the string.

  **THIS IS A LOSSY CONVERSION**.
  ```elixir
      iex> Exsemantica.Handle128.convert_to("老干妈")
      {:ok, "lao_gan_ma"}
  ```
  """
  def convert_to(item) do
    case item
         |> Unidecode.decode()
         |> String.trim()
         |> String.replace(" ", "_")
         |> String.downcase() do
      ascii when is_valid(ascii) ->
        if valid?(ascii) do
          {:ok, ascii}
        else
          {:error, :not_ascii}
        end

      _ ->
        {:error, :transliteration}
    end
  end

  @doc """
  Checks if what may be a Handle128 is a valid Handle128

  We check it against RFC 2812 nickname validity, except we'll be using
  16-byte nicknames/handles, and not shorter ones
  """
  def valid?(item) when is_valid(item) do
    # Convert to charlist
    [first | rest] = item |> to_charlist()

    # Is the first character valid?
    first_valid? = is_irc_letter(first) or is_irc_special(first)

    # Are the rest valid?
    rest_valid? =
      rest
      |> Enum.all?(fn char ->
        is_irc_letter(char) or is_irc_special(char) or is_irc_digit(char) or char === ?-
      end)

    # Make sure they're both valid
    first_valid? and rest_valid?
  end

  # Otherwise if `is_valid` catches something too long it's not valid
  def valid?(_item), do: false
end
