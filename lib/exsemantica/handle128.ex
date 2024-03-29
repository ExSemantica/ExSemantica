defmodule Exsemantica.Handle128 do
  @moduledoc """
  A Handle128 is a 16-char ASCII identifier, that can be tested for equality by
  most SIMD engines.
  """

  defguard is_valid(item) when is_binary(item) and byte_size(item) > 0 and byte_size(item) <= 16

  @doc """
  Converts a handle into a Handle128 with at most 16 characters.
  **THIS IS A LOSSY CONVERSION**.
  ```elixir
      iex> Exsemantica.Handle128.convert_to("老干妈")
      {:ok, "Lao_Gan_Ma      "}
  ```
  """
  def convert_to(item) do
    case item
         |> Unidecode.decode()
         |> String.trim()
         |> String.replace(" ", "_") do
      ascii when is_valid(ascii) ->
        chars_ascii? =
          ascii
          |> to_charlist()
          |> Enum.all?(&(&1 in 0x21..0x7E))

        if chars_ascii? do
          {:ok, ascii}
        else
          :error
        end

      _ ->
        :error
    end
  end
end
