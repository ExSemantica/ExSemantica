defmodule Exsemantica.ApplicationInfo do
  @doc """
  Refresh the application metadata
  """
  def refresh do
    :persistent_term.put(__MODULE__.LastRefreshed, DateTime.utc_now())
  end

  @doc """
  Gets the last refreshed UTC DateTime.

  Call `Exsemantica.ApplicationInfo.refresh` once before using this
  function.
  """
  def get_last_refreshed, do: :persistent_term.get(__MODULE__.LastRefreshed)
end
