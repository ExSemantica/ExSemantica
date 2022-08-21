defmodule ExSemantica.Api.Router do
  @moduledoc """
  Root endpoint router for API access. Forwards to other local endpoints.
  """
  use Plug.Router

  plug(Plug.Logger)
  plug(:match)
  plug(:dispatch)

  get "/ping" do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{status: :ok}))
  end

  match _ do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(404, Jason.encode!(%{status: :not_found}))
  end
end
