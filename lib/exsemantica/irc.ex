defmodule Exsemantica.IRC do
  @moduledoc """
  Handle low-level IRC connections.
  """

  def channel_limit(), do: 16

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

  @doc """
  Lists parameter iolists to send in the welcome burst.
  """
  def get_parameters() do
    [
      "CASEMAPPING=ascii",
      "CHANMODES=b",
      ["CHANLIMIT=#:", channel_limit() |> to_string],
      ["CHANNELLEN=", Exsemantica.Repo.Aggregate.max_name_length() |> to_string],
      "CHANTYPES=#",
      "NETWORK=ExSemantica",
      ["NICKLEN=", Exsemantica.Repo.User.max_name_length() |> to_string],
      "PREFIX=@",
      ["TOPICLEN=", Exsemantica.Repo.Aggregate.max_description_length() |> to_string],
      ["USERLEN=", Exsemantica.IRC.User.max_id36_len() |> to_string]
    ]
  end
end
