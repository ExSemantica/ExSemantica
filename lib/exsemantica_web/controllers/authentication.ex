defmodule ExsemanticaWeb.Authentication do
  require Logger
  use ExsemanticaWeb, :controller
  alias Exsemantica.Backbone.Authentication, as: Authentication

  @minutes_grace 10

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
          |> fetch_session
          |> Exsemantica.Guardian.Plug.sign_in(user, %{typ: "access"},
            ttl: {@minutes_grace, :minutes}
          )

        conn
        |> put_status(200)
        |> json(%{
          e: false,
          message: "Signing in as '#{user.handle}'"
        })
    end
  end

  def log_out(conn, _params) do
    conn
    |> fetch_session
    |> Authentication.log_out()
    |> send_resp(204, "")
  end
end
