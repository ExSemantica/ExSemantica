defmodule Exsemantica.IRC.Numerics.SASL do
  def handle(user = %{nickname: nickname}, numeric = 900) do
    [
      %Exsemantica.IRC.Message{
        prefix: ExsemanticaWeb.Endpoint.host(),
        command: numeric,
        params: [nickname, user |> Exsemantica.IRC.User.construct_hostmask(), nickname],
        trailing: ["You are now logged in as ", nickname]
      }
    ]
  end

  def handle(user = %{nickname: nickname}, numeric = 901) do
    [
      %Exsemantica.IRC.Message{
        prefix: ExsemanticaWeb.Endpoint.host(),
        command: numeric,
        params: [nickname, user |> Exsemantica.IRC.User.construct_hostmask()],
        trailing: "You are now logged out"
      }
    ]
  end

  def handle(%{nickname: nickname}, numeric = 902) do
    [
      %Exsemantica.IRC.Message{
        prefix: ExsemanticaWeb.Endpoint.host(),
        command: numeric,
        params: [nickname],
        trailing: "You must use a nick assigned to you"
      }
    ]
  end

  def handle(%{nickname: nickname}, numeric = 903) do
    [
      %Exsemantica.IRC.Message{
        prefix: ExsemanticaWeb.Endpoint.host(),
        command: numeric,
        params: [nickname],
        trailing: "SASL authentication successful"
      }
    ]
  end

  def handle(%{nickname: nickname}, numeric = 904) do
    [
      %Exsemantica.IRC.Message{
        prefix: ExsemanticaWeb.Endpoint.host(),
        command: numeric,
        params: [nickname],
        trailing: "SASL authentication failed"
      }
    ]
  end

  def handle(%{nickname: nickname}, numeric = 905) do
    [
      %Exsemantica.IRC.Message{
        prefix: ExsemanticaWeb.Endpoint.host(),
        command: numeric,
        params: [nickname],
        trailing: "SASL message too long"
      }
    ]
  end

  def handle(%{nickname: nickname}, numeric = 906) do
    [
      %Exsemantica.IRC.Message{
        prefix: ExsemanticaWeb.Endpoint.host(),
        command: numeric,
        params: [nickname],
        trailing: "SASL authentication aborted"
      }
    ]
  end

  def handle(%{nickname: nickname}, numeric = 907) do
    [
      %Exsemantica.IRC.Message{
        prefix: ExsemanticaWeb.Endpoint.host(),
        command: numeric,
        params: [nickname],
        trailing: "You have already authenticated using SASL"
      }
    ]
  end

  def handle(%{nickname: nickname}, numeric = 908) do
    [
      %Exsemantica.IRC.Message{
        prefix: ExsemanticaWeb.Endpoint.host(),
        command: numeric,
        params: [nickname, "PLAIN"],
        trailing: "are available SASL mechanisms"
      }
    ]
  end
end
