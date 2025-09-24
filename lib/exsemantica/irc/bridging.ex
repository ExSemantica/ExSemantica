defmodule Exsemantica.IRC.Bridging do
  @moduledoc """
  IRC bridge numerics, automatically parsed out...

  TODO: Delete or refactor this since we are handling numerics differently.
  """

  def handle(:RPL_WELCOME, data) do
    [":#{data.source} 001 #{data.client} :Welcome to ExSemantica chat, #{data.client}"]
  end

  def handle(:RPL_YOURHOST, data) do
    [
      ":#{data.source} 002 #{data.client} :Your host is #{data.source}, running version #{data.server_version}"
    ]
  end

  def handle(:RPL_CREATED, data) do
    [":#{data.source} 003 #{data.client} :This server was created #{data.server_created}"]
  end

  def handle(:RPL_MYINFO, data) do
    # w: users can be walled
    # b: users can be banned from channels
    [":#{data.source} 004 #{data.client} #{data.source} exsemantica-#{data.server_version} w b b"]
  end

  def handle(:RPL_ISUPPORT, data) do
    # TODO: more RPL_ISUPPORT tokens, see https://modern.ircdocs.horse/
    [
      ":#{data.source} 005 #{data.client} CASEMAPPING=ascii CHANMODES=b CHANNELLEN=31 CHANTYPES=# PREFIX=@ USERLEN=15 :are supported by this server"
    ]
  end

  def handle(:RPL_MOTDSTART, data) do
    [":#{data.source} 375 #{data.client} :=== Message of the Day ==="]
  end

  def handle(:RPL_MOTD, data) do
    :persistent_term.get(__MODULE__.MOTD)
    |> Enum.map(fn line ->
      ":#{data.source} 372 #{data.client} :#{line}"
    end)
  end

  def handle(:RPL_ENDOFMOTD, data) do
    [":#{data.source} 376 #{data.client} :End of /MOTD command"]
  end

  def handle(:ERR_NICKNAMEINUSE, data) do
    [":#{data.source} 433 #{data.client} #{data.client} :Nickname already in use"]
  end

  def handle(:ERR_YOUREBANNEDCREEP, data) do
    [":#{data.source} 465 #{data.client} :You are banned from this server"]
  end
end
