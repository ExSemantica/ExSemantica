defmodule Exsemantica.Backbone.Authentication do
  @moduledoc """
  Logic for authenticating users.
  """
  import Ecto.Query

  @doc """
  Checks if the user information specified is correct to log in.
  """
  def check_user(username, password) do
    user_data =
      Exsemantica.Repo.one(from u in Exsemantica.User, where: ilike(u.handle, ^username))

    case user_data do
      nil ->
        {:error, :enoent}

      %Exsemantica.User{password: stored_hash} ->
        if Argon2.verify_pass(password, stored_hash) do
          {:ok, user_data}
        else
          {:error, :unauthorized}
        end
    end
  end
end
