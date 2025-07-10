defmodule Exsemantica.IRC do
  @moduledoc """
  Handle low-level IRC connections.
  """

  @doc """
  Reloads IRC server priv data.

  This currently handles the Message of the Day.
  """
  def rehash() do
    # rehash MOTD
    motd =
      File.read!(
        Path.join([
          :code.priv_dir(:exsemantica) |> to_string,
          "motd.txt"
        ])
      )
      |> String.split("\n")

    :persistent_term.put(__MODULE__.StoredMOTD, motd)
  end
end
