defmodule ExsemanticaWeb.AuthenticationError do
  require Logger
  use ExsemanticaWeb, :controller
  @behaviour Guardian.Plug.ErrorHandler
  def auth_error(conn, error, opts) do
    Logger.error(inspect(error))

    conn
    |> put_status(500)
    |> json(%{e: true, message: "An unexpected error occured"})
  end
end
