defmodule Exsemantica.ApplicationInfo do
  @moduledoc """
  Handle retrieval of application metadata
  """

  @doc """
  Refresh the application metadata
  """
  def refresh do
    :persistent_term.put(__MODULE__.LastRefreshed, DateTime.utc_now())

    # Get the git commit SHA
    git_commit =
      Application.get_env(:exsemantica, __MODULE__, %{commit_sha_result: :release})[
        :commit_sha_result
      ]

    # Concatenate it to the Application version, complying with SemVer
    version =
      to_string(Application.spec(:exsemantica, :vsn)) <>
        if git_commit == :release do
          ""
        else
          {git_commit_sha, 0} = git_commit
          "+git-" <> (git_commit_sha |> String.trim_trailing("\n"))
        end

    # Put it in a persistent_term
    :persistent_term.put(__MODULE__.Version, version)
  end

  @doc """
  Get the application version as a string

  You must have called `Exsemantica.ApplicationInfo.refresh` at least once
  before this
  """
  def get_version do
    :persistent_term.get(__MODULE__.Version)
  end

  @doc """
  Gets the last refreshed UTC DateTime.

  Call `Exsemantica.ApplicationInfo.refresh` once before using this
  function.
  """
  def get_last_refreshed, do: :persistent_term.get(__MODULE__.LastRefreshed)
end
