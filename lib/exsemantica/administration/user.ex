defmodule Exsemantica.Administration.User do
  def create(username, password, email, biography) do
    Exsemantica.Repo.insert(%Exsemantica.Repo.User{
      username: username,
      password: Argon2.hash_pwd_salt(password),
      email: email,
      biography: biography
    })
  end
end
