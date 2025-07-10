defmodule Exsemantica.IRC.Numerics.MOTD do
  def handle(%{nickname: nickname}, numeric = 372) do
    source = ExsemanticaWeb.Endpoint.host()

    :persistent_term.get(Exsemantica.IRC.StoredMOTD)
    |> Enum.map(
      &%Exsemantica.IRC.Message{
        prefix: source,
        command: numeric,
        params: [nickname],
        trailing: &1
      }
    )
  end

  def handle(%{nickname: nickname}, numeric = 375) do
    [
      %Exsemantica.IRC.Message{
        prefix: ExsemanticaWeb.Endpoint.host(),
        command: numeric,
        params: [nickname],
        trailing: "=== Message of the Day ==="
      }
    ]
  end

  def handle(%{nickname: nickname}, numeric = 376) do
    [
      %Exsemantica.IRC.Message{
        prefix: ExsemanticaWeb.Endpoint.host(),
        command: numeric,
        params: [nickname],
        trailing: "End of /MOTD command"
      }
    ]
  end
end
