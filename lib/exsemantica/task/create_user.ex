defmodule Exsemantica.Task.CreateUser do
  @moduledoc """
  A task that registers a user
  """
  @behaviour Exsemantica.Task

  @impl true
  def run(%{
        username: username,
        password: password,
        email: email,
        invite_code: invite_code
      }) do
    invite_invalid? =
      if Exsemantica.Auth.using_invite_codes?() do
        invite_code != :persistent_term.get(Exsemantica.InviteCode)
      else
        false
      end

    constrained = Exsemantica.Constrain.into_valid_username(username)
    user_invalid? = :error == constrained

    auth_invalid? = :ok != Exsemantica.Auth.check_free(username, email)

    cond do
      invite_invalid? ->
        {:error, {:invalid, :invite}}

      user_invalid? ->
        {:error, {:invalid, :username}}

      auth_invalid? ->
        {:error, {:invalid, :auth}}

      true ->
        {:ok, constrained_ok} = constrained
        :persistent_term.put(Exsemantica.InviteCode, ) #TODO
        Exsemantica.Repo.insert(%Exsemantica.Repo.User{
          username: constrained_ok,
          password: Argon2.hash_pwd_salt(password),
          email: email,
          biography: nil
        })
    end
  end
end
