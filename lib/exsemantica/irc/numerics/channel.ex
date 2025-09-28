defmodule Exsemantica.IRC.Numerics.Channel do
  def handle(%{nickname: nickname, channel: channel, topic: topic}, numeric = 332) do
    source = ExsemanticaWeb.Endpoint.host()

    %Exsemantica.IRC.Message{
      prefix: source,
      command: numeric,
      params: [nickname, channel],
      trailing: topic
    }
  end

  def handle(%{nickname: nickname, channel: channel, date: date}, numeric = 333) do
    source = ExsemanticaWeb.Endpoint.host()

    %Exsemantica.IRC.Message{
      prefix: source,
      command: numeric,
      params: [nickname, channel, "Services", date |> DateTime.to_unix() |> to_string]
    }
  end

  def handle(%{nickname: nickname, channel: channel, users: users}, numeric = 353) do
    source = ExsemanticaWeb.Endpoint.host()

    %Exsemantica.IRC.Message{
      prefix: source,
      command: numeric,
      params: [nickname, "=", channel],
      trailing: users |> Enum.join(" ")
    }
  end

  def handle(%{nickname: nickname, channel: channel}, numeric = 366) do
    source = ExsemanticaWeb.Endpoint.host()

    %Exsemantica.IRC.Message{
      prefix: source,
      command: numeric,
      params: [nickname, channel],
      trailing: "End of /NAMES list"
    }
  end

  def handle(%{nickname: nickname, channel: channel}, numeric = 442) do
    source = ExsemanticaWeb.Endpoint.host()

    %Exsemantica.IRC.Message{
      prefix: source,
      command: numeric,
      params: [nickname, channel],
      trailing: "You're not on that channel"
    }
  end

  def handle(%{nickname: nickname, channel: channel}, numeric = 471) do
    source = ExsemanticaWeb.Endpoint.host()

    %Exsemantica.IRC.Message{
      prefix: source,
      command: numeric,
      params: [nickname, channel],
      trailing: "Cannot join channel (too many users)"
    }
  end

  def handle(%{nickname: nickname, channel: channel, reason: reason}, numeric = 474) do
    source = ExsemanticaWeb.Endpoint.host()

    %Exsemantica.IRC.Message{
      prefix: source,
      command: numeric,
      params: [nickname, channel],
      trailing: ["Cannot join channel (you have been banned (", reason, "))"]
    }
  end
end
