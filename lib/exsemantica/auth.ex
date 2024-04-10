defmodule Exsemantica.Auth do
  @moduledoc """
  Low-level authentication code goes into this namespace
  """
  import Ecto.Query

  @doc """
  Checks if the username and password correspond to a user in the database
  """
  def check_user(username, password) do
    user_data =
      Exsemantica.Repo.one(from u in Exsemantica.Repo.User, where: ilike(u.username, ^username))

    case user_data do
      # User not found
      nil ->
        # Try not to let hash timing attacks succeed
        Argon2.no_user_verify()
        {:error, :not_found}

      # User found, authenticate them
      %Exsemantica.Repo.User{password: hash} ->
        if Argon2.verify_pass(password, hash) do
          {:ok, user_data}
        else
          {:error, :unauthorized}
        end
    end
  end

  @doc """
  Checks if the authentication token is valid
  """
  def check_token(token) do
    resource = Exsemantica.Auth.Guardian.resource_from_token(token)

    case resource do
      {:ok, user, _claims} ->
        {:ok, user}

      {:error, error} ->
        {:error, error}
    end
  end

  @doc """
  Checks if the username or or username/e-mail combination are free to be used
  """
  def check_free(username, email) do
    user_data =
      Exsemantica.Repo.one(from u in Exsemantica.Repo.User, where: ilike(u.username, ^username))

    email_valid? = EmailChecker.valid?(email)

    case user_data do
      # User  doesn't exist
      nil when email_valid? ->
        :ok

      # User doesn't exist and the email is invalid
      nil ->
        {:error, :invalid}

      # User exists
      _user ->
        {:error, :user_exists}
    end
  end

  @spec using_invite_codes?() :: boolean()
  @doc """
  Returns true if this Exsemantica instance is using invite codes
  """
  def using_invite_codes?() do
    Application.get_env(:exsemantica, __MODULE__)[:use_invite_codes]
  end
end
