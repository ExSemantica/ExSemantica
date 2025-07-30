defmodule Exsemantica.IRC.Numerics.Welcome do
  def handle(%{nickname: nickname}, numeric = 1) do
    [
      %Exsemantica.IRC.Message{
        prefix: ExsemanticaWeb.Endpoint.host(),
        command: numeric,
        params: [nickname],
        trailing: [
          "Welcome to ExSemantica chat, ",
          nickname
        ]
      }
    ]
  end

  def handle(%{nickname: nickname}, numeric = 2) do
    source = ExsemanticaWeb.Endpoint.host()

    [
      %Exsemantica.IRC.Message{
        prefix: source,
        command: numeric,
        params: [nickname],
        trailing: [
          "Your host is ",
          source,
          " running version ",
          Application.spec(:exsemantica, :vsn) |> to_string
        ]
      }
    ]
  end

  def handle(%{nickname: nickname}, numeric = 3) do
    source = ExsemanticaWeb.Endpoint.host()

    [
      %Exsemantica.IRC.Message{
        prefix: source,
        command: numeric,
        params: [nickname],
        trailing: [
          "This server was last reloaded or restarted ",
          Exsemantica.ApplicationInfo.get_last_refreshed() |> DateTime.to_string()
        ]
      }
    ]
  end

  def handle(%{nickname: nickname}, numeric = 4) do
    source = ExsemanticaWeb.Endpoint.host()

    # w: users can be walled
    # b: channels can have users banned from them
    # b: channel bans require a parameter

    [
      %Exsemantica.IRC.Message{
        prefix: ExsemanticaWeb.Endpoint.host(),
        command: numeric,
        params: [
          nickname,
          source,
          ["exsemantica-", Application.spec(:exsemantica, :vsn) |> to_string],
          "w",
          "b",
          "b"
        ]
      }
    ]
  end

  def handle(%{nickname: nickname}, numeric = 5) do
    Exsemantica.IRC.get_parameters()
    |> Enum.chunk_every(13)
    |> Enum.map(fn parameters_chunk ->
      %Exsemantica.IRC.Message{
        prefix: ExsemanticaWeb.Endpoint.host(),
        command: numeric,
        params: [nickname | parameters_chunk],
        trailing: "are supported by this server"
      }
    end)
  end
end
