defmodule Exsemantica.IRC.Numerics.Welcome do
  def handle(user = %{nickname: nickname}, numeric = 1) do
    [
      %Exsemantica.IRC.Message{
        prefix: ExsemanticaWeb.Endpoint.host(),
        command: numeric,
        params: [nickname],
        trailing: [
          "Welcome to ExSemantica chat, ",
          user |> Exsemantica.IRC.User.construct_hostmask()
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
    [
      %Exsemantica.IRC.Message{
        prefix: ExsemanticaWeb.Endpoint.host(),
        command: numeric,
        params: [
          nickname,
          "CASEMAPPING=ascii",
          "CHANMODES=b",
          # TODO: channel length is a magic number, FIXME
          "CHANNELLEN=31",
          "CHANTYPES=#",
          "PREFIX=@",
          ["USERLEN=", Exsemantica.IRC.User.get_max_id36_len() |> to_string]
        ],
        trailing: "are supported by this server"
      }
    ]
  end
end
