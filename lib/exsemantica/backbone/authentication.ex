defmodule Exsemantica.Backbone.Authentication do
  @moduledoc """
  Logic for authenticating users.
  """
  require Logger
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

  def verify_token(token) do
    res = Exsemantica.Guardian.resource_from_token(token)

    case res do
      {:ok, user, _claims} ->
        {:ok, user}

      {:error, error} ->
        {:error, error}
    end
  end

  def log_out(conn) do
    conn
    |> Exsemantica.Guardian.Plug.sign_out()
  end
end
