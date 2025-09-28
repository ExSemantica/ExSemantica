defmodule Exsemantica.IRC.Numerics do
  @moduledoc """
  SEE: IRCv3 docs for more information on what these mean.
  """

  # IRCv3 standard mappings go here
  @mappings %{
    RPL_WELCOME: 1,
    RPL_YOURHOST: 2,
    RPL_CREATED: 3,
    RPL_MYINFO: 4,
    RPL_ISUPPORT: 5,
    RPL_UMODEIS: 221,
    RPL_LUSERCLIENT: 251,
    RPL_LUSERME: 255,
    RPL_TOPIC: 332,
    RPL_TOPICWHOTIME: 333,
    RPL_NAMREPLY: 353,
    RPL_ENDOFNAMES: 366,
    RPL_MOTD: 372,
    RPL_MOTDSTART: 375,
    RPL_ENDOFMOTD: 376,
    ERR_NOTONCHANNEL: 442,
    ERR_CHANNELISFULL: 471,
    ERR_BANNEDFROMCHAN: 473,
    RPL_LOGGEDIN: 900,
    RPL_LOGGEDOUT: 901,
    ERR_NICKLOCKED: 902,
    RPL_SASLSUCCESS: 903,
    ERR_SASLFAIL: 904,
    ERR_SASLTOOLONG: 905,
    ERR_SASLABORTED: 906,
    ERR_SASLALREADY: 907,
    RPL_SASLMECHS: 908
  }

  @doc """
  Maps an atom to its appropriate IRC numeric.
  """
  def to_numeric(mapping), do: @mappings[mapping]

  @doc """
  Returns a list of IRC packet structures sent.

  Do be warned that inside these structures, sometimes items can be iolists.
  """
  def handle(user, numeric) when numeric >= 1 and numeric < 6 do
    __MODULE__.Welcome.handle(user, numeric)
  end

  def handle(user, numeric) when numeric >= 900 and numeric < 909 do
    __MODULE__.SASL.handle(user, numeric)
  end

  def handle(user, numeric) when numeric in [251, 255] do
    __MODULE__.LUsers.handle(user, numeric)
  end

  def handle(user, numeric) when numeric in [372, 375, 376] do
    __MODULE__.MOTD.handle(user, numeric)
  end

  def handle(user, numeric) when numeric in [332, 333, 353, 366, 442, 471, 474] do
    __MODULE__.Channel.handle(user, numeric)
  end
end
