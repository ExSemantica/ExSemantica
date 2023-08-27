defmodule Exsemantica.AggHandle do
  @moduledoc """
  An AggHandle is a lowercase ASCII identifier used to identify aggregates.
  """
  require Exsemantica.HandleGuards, as: Guards

  @doc """
  Converts a handle into an AggHandle with at most 32 characters.
  **THIS IS A LOSSY CONVERSION**.
  ```elixir
      iex> Exsemantica.AggHandle.convert_to("老干妈")
      {:ok, "lao_gan_ma"}
  ```
  """
  def convert_to(item) do
    case item
         |> Unidecode.decode()
         |> String.trim()
         |> String.replace(" ", "_") do
      ascii when Guards.is_valid_agg_pre(ascii) ->
        chars_ascii? =
          ascii
          |> to_charlist()
          |> Enum.all?(&Guards.is_valid_char/1)

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
