# Copyright 2019-2022 Roland Metivier
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
defmodule ExSemantica.Types.Handle128 do
  @moduledoc """
  A Handle128 is a 16-char ASCII identifier, that can be tested for equality by
  most SIMD engines.
  """

  defguard is_valid(item) when is_binary(item) and byte_size(item) > 0 and byte_size(item) <= 16

  @doc """
  Converts a 16-char handle into its Handle128.
  **This is a lossy conversion** since it transliterates the input into ASCII
  symbols.
  """
  def encode(item) do
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
          {:error, :einval}
        end

      _invalid ->
        {:error, :einval}
    end
  end
end
