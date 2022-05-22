defmodule ExsemanticaWeb.Types.Handle128 do
  @moduledoc """
  A Handle128 is a 16-char ASCII identifier, that can be tested for equality by
  most SIMD engines.
  """

  defguard is_valid(item) when is_binary(item) and byte_size(item) > 0 and byte_size(item) <= 16

  @doc """
  Converts a 16-char handle into its Handle128.
  **THIS IS A LOSSY CONVERSION**.
  """
  def convert(item) do
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
          {:ok, ascii |> String.pad_trailing(16)}
        else
          :error
        end

      _ ->
        :error
    end
  end

    @doc """
  Converts a 16-char handle into its Handle128, not padding to 16 bytes.
  **THIS IS A LOSSY CONVERSION**.
  """
  def convert_nopadding(item) do
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
