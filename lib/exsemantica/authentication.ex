defmodule Exsemantica.Authentication do
  @moduledoc """
  Quick way to check user authenticity
  """
  import Ecto.Query

  def check_user(username, password) do
    data =
      Exsemantica.Repo.one(
        from u in Exsemantica.Repo.User, where: ilike(u.username, ^username), select: u
      )

    case data do
      nil ->
        {:error, :no_such_user}

      real_data = %Exsemantica.Repo.User{
        banned?: true,
        banned_expire: expiry,
        banned_reason: reason
      } ->
        if is_nil(expiry) or DateTime.utc_now() |> DateTime.before?(expiry) do
          {:error, {:banned, reason, expiry}}
        else
          Ecto.Changeset.change(real_data, %{
            banned?: false,
            banned_expire: nil,
            banned_reason: "No reason given"
          })
          |> Exsemantica.Repo.update()
        end

      real_data = %Exsemantica.Repo.User{password: hash} ->
        if Argon2.verify_pass(password, hash) do
          # Password is correct
          {:ok, real_data}
        else
          # Password is not correct but we wait
          Argon2.no_user_verify()
          {:error, :invalid_auth}
        end
    end
  end

  def get_user_error(:no_such_user), do: "User not found"
  def get_user_error(:invalid_auth), do: "Authentication failed"

  def get_user_error({:banned, reason, nil}) do
    ["You are banned (reason: '", reason, "', no expiry)"]
  end

  def get_user_error({:banned, reason, expiry}) do
    ["You are banned (reason: '", reason, "', expires: ", expiry |> DateTime.to_string(), ")"]
  end
end
