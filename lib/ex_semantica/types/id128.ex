defmodule ExSemantica.Types.Id128 do
  @moduledoc """
  An ID128 is a 128-bit identifier, that can be tested for equality by most
  SIMD engines.
  """

  defguard is_valid(item) when is_binary(item) and byte_size(item) == 16

  @doc """
  Converts a 16-byte binary into its base-64 ID128.
  ```elixir
      iex> ExSemantica.Types.Id128.to_base64(<<0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15>>)
      {:ok, "AAECAwQFBgcICQoLDA0ODw=="}
  ```
  """
  def to_base64(item) do
    case item do
      item when is_valid(item) -> {:ok, Base.url_encode64(item)}
      _ -> {:error, :einval}
    end
  end


  @doc """
  Converts a base-64 ID128 into a 16-byte binary.
  ```elixir
      iex> ExSemantica.Types.Id128.from_base64("AAECAwQFBgcICQoLDA0ODw==")
      {:ok, <<0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15>>}
  ```
  """
  def from_base64(item) do
    base64 = Base.url_decode64(item)

    case base64 do
      {:ok, extracted} when is_valid(extracted) -> {:ok, extracted}
      _ -> {:error, :einval}
    end
  end
end
