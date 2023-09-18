defmodule ExsemanticaWeb.Authentication do
  use ExsemanticaWeb, :controller
  alias Exsemantica.Backbone.Authentication, as: Authentication

  @minutes_grace 5

  def log_in(conn, %{"username" => username, "password" => password}) do
    case Authentication.check_user(username, password) do
      {:error, :unauthorized} ->
        conn
        |> put_status(401)
        |> json(%{e: true, message: "Your password is incorrect"})

      {:error, :enoent} ->
        conn
        |> put_status(404)
        |> json(%{e: true, message: "User not found"})

      {:ok, user} ->
        conn =
          conn
          |> Exsemantica.Guardian.Plug.sign_in(user, %{typ: "access"}, ttl: {@minutes_grace, :minutes})

        conn
        |> put_status(200)
        |> json(%{
          e: false,
          message: "Signing in as '#{user.handle}'",
          token: conn |> Exsemantica.Guardian.Plug.current_token()
        })
    end
  end
end
