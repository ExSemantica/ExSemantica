defmodule ExsemanticaWeb.APIv0.Login do
  use ExsemanticaWeb, :controller

  require Exsemnesia.Handle128

  def get_attributes(conn, _opts) do
    conn = conn |> fetch_query_params()

    case conn.query_params do
      %{"user" => user} ->
        handle = Exsemnesia.Handle128.serialize(user)

        case handle do
          :error ->
            {:ok, json} =
              Jason.encode(%{
                success: false,
                error_code: "E_INVALID_USERNAME",
                description: "The username is invalid."
              })

            conn |> send_resp(400, json)

          transliterated ->
            {:ok, json} =
              Jason.encode(%{
                success: true,
                parsed: transliterated,
                unique: Exsemnesia.Utils.unique?(String.downcase(transliterated, :ascii))
              })

            conn |> send_resp(200, json)
        end

      _ ->
        {:ok, json} =
          Jason.encode(%{
            success: false,
            error_code: "E_NO_USERNAME",
            description: "The username has to be specified."
          })

        conn |> send_resp(400, json)
    end
  end

  def post_authentication(conn, _opts) do
    case Exsemnesia.Auth.login(conn.body_params["user"], conn.body_params["pass"]) do
      {:ok, token} ->
        {:ok, json} =
          Jason.encode(%{
            success: true,
            # The handle of the user.
            handle: token.handle
          })

        conn
        |> fetch_session()
        |> put_session(
          :exsemantica_apitoken,
          Phoenix.Token.sign(ExsemanticaWeb.EndpointApi, "user token", token)
        )
        |> send_resp(200, json)

      {:error, :rate} ->
        {:ok, json} =
          Jason.encode(%{
            success: false,
            error_code: "E_RATE_LIMIT",
            description: "You are being rate limited."
          })

        conn |> send_resp(429, json)

      {:error, :invalid} ->
        {:ok, json} =
          Jason.encode(%{
            success: false,
            error_code: "E_INVALID_USERNAME",
            description: "The username is invalid."
          })

        conn |> send_resp(400, json)

      {:error, :auth} ->
        {:ok, json} =
          Jason.encode(%{
            success: false,
            error_code: "E_AUTHENTICATION",
            description: "Authentication failed."
          })

        conn |> send_resp(401, json)

      {:error, :no_exist} ->
        {:ok, json} =
          Jason.encode(%{
            success: false,
            error_code: "E_NO_USERNAME",
            description: "The account with that handle does not exist, or it isn't activated."
          })

        conn |> send_resp(400, json)
    end
  end

  def put_registration(conn, _opts) do
    prefs = :persistent_term.get(:exsemprefs)
    invite_incoming = conn.body_params["invite"]
    invite_outgoing = Base.url_encode64(:persistent_term.get(:exseminvite))
    no_registration = not prefs.registration_enabled

    cond do
      no_registration ->
        {:ok, json} =
          Jason.encode(%{
            success: false,
            error_code: "E_NO_REGISTRATIONS",
            description: "Registration is disabled on this instance."
          })

        conn |> send_resp(401, json)

      invite_incoming != invite_outgoing ->
        {:ok, json} =
          Jason.encode(%{
            success: false,
            error_code: "E_INVITE_INVALID",
            description: "The invite code is invalid."
          })

        conn |> send_resp(400, json)

      invite_incoming == invite_outgoing ->
        handle = Exsemnesia.Handle128.serialize(conn.body_params["user"])
        result = Exsemnesia.Utils.create_user(handle, conn.body_params["pass"])

        case result do
          {:error, :eusers} ->
            {:ok, json} =
              Jason.encode(%{
                success: false,
                error_code: "E_USER_EXISTS",
                description: "The user already exists."
              })

            conn |> send_resp(400, json)

          {:error, :einval} ->
            {:ok, json} =
              Jason.encode(%{
                success: false,
                error_code: "E_INVALID_USERNAME",
                description: "The username is invalid."
              })

            conn |> send_resp(400, json)

          {:ok, %{handle: handle, token: token}} ->
            {:ok, json} =
              Jason.encode(%{
                success: true,
                # The handle of the user.
                handle: handle,
                token: token
              })

            conn |> send_resp(200, json)
        end
    end
  end
end
