defmodule Exsemantica.IRC.Numerics.LUsers do
  # NOTE: Only one server is currently supported
  # TODO: Make us support more than one server
  # TODO: Fix the servercount magic number after this
  def handle(%{nickname: nickname}, numeric = 251) do
    %{active: active} = DynamicSupervisor.count_children(Exsemantica.IRC.UserSupervisor)

    [
      %Exsemantica.IRC.Message{
        prefix: ExsemanticaWeb.Endpoint.host(),
        command: numeric,
        params: [nickname],
        trailing: [
          "There are ",
          active |> to_string(),
          " user(s) and 0 invisible on 1 server"
        ]
      }
    ]
  end

  def handle(%{nickname: nickname}, numeric = 255) do
    %{active: active} = DynamicSupervisor.count_children(Exsemantica.IRC.UserSupervisor)

    [
      %Exsemantica.IRC.Message{
        prefix: ExsemanticaWeb.Endpoint.host(),
        command: numeric,
        params: [nickname],
        trailing: [
          "I have ",
          active |> to_string(),
          " client(s) and 1 server(s)"
        ]
      }
    ]
  end
end
