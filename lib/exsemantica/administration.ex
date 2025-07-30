defmodule Exsemantica.Administration do
  @moduledoc """
  Convenience functions for system administrators to manipulate ExSemantica.
  """
  import Ecto.Query

  def force_disconnect(handle, reason) do
    id =
      Exsemantica.Repo.one(
        from u in Exsemantica.Repo.User, where: ilike(^handle, u.username), select: u.id
      )

    if is_integer(id) do
      Exsemantica.IRC.UserProcess.force_disconnect(id, reason)
    else
      :error
    end
  end
end
