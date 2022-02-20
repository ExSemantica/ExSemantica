defmodule Exsemnesia.Handle128 do
  @moduledoc """
  A Handle128 is a 16-char ASCII identifier, that can be tested for equality by
  most SIMD engines.
  """

  defguard is_valid(item) when is_binary(item) and byte_size(item) > 0 and byte_size(item) <= 16

  @doc """
  Converts a 16-char handle into its Handle128.
  **THIS IS A LOSSY CONVERSION**.
  """
  def serialize(item) do
    case Unidecode.decode(item) do
      ascii when is_valid(ascii) -> String.pad_trailing(ascii, 16)
      _ -> :error
    end
  end

  @doc """
  Converts a Handle128 into a 16-byte binary.
  """
  def parse(%Absinthe.Blueprint.Input.String{value: item}) do
    # requires nothing, lossy conversion is done and over with.
    {:ok, item}
  end
end