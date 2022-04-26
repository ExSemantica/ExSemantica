defmodule Exsemnesia.Auth do
  @moduledoc """
  Authentication for users.
  """
  require Exsemnesia.Handle128
  require Logger

  # Define an amount in seconds for us to rate limit logins
  @back_off 5

  # Token expires after this amount in seconds
  @expires_after 3600

  @doc """
  Logs in by handle and hashed password. Sanity checks are performed.
  """
  def login(raw_handle, password) do
    # Check for initial validity
    unless Exsemnesia.Handle128.is_valid(raw_handle) do
      # Then check for the serialized result
      case Exsemnesia.Handle128.serialize(raw_handle) do
        :error ->
          # At this branch we have an invalid handle, stop.
          Logger.debug("handle #{raw_handle} partial INVALID")
          {:error, :invalid}

        handle ->
          # The handle is for sure valid, we may look for it
          downcased = String.downcase(handle)
          Logger.debug("handle #{raw_handle} valid, maps to #{downcased}")

          {:atomic, [auth_head]} =
            [Exsemnesia.Utils.get(:auth, downcased)]
            |> Exsemnesia.Database.transaction("try to log in user")

          # okay now look in our database
          case auth_head.response do
            # nobody
            [] ->
              Logger.debug("handle #{raw_handle} valid, maps to #{downcased}, NONEXISTENT")
              {:error, :no_exist}

            # somebody
            [{:auth, ^downcased, secret, _token, bounce}] ->
              new_bounce = DateTime.utc_now()

              case new_bounce |> DateTime.compare(bounce) do
                :lt ->
                  Logger.warning("handle #{handle} logging in too fast")
                  {:error, :rate}

                _ ->
                  case Argon2.check_pass(secret, password) do
                    # all clear
                    {:ok, _} ->
                      Logger.info("handle #{handle} successfully logged in")

                      [
                        Exsemnesia.Utils.put(
                          :auth,
                          {:auth, downcased, secret,
                           token = %{
                             handle: downcased,
                             nonce: Base.url_encode64(:crypto.strong_rand_bytes(16)),
                             exp: new_bounce |> DateTime.add(@expires_after)
                           }, new_bounce |> DateTime.add(@back_off)}
                        )
                      ]
                      |> Exsemnesia.Database.transaction("update user login nonces")

                      {:ok, token}

                    # incorrect password?
                    {:error, error} ->
                      Logger.warning("handle #{handle} argon2 fail #{error}")
                      {:error, :auth}
                  end
              end
          end
      end
    else
      Logger.debug("handle #{raw_handle} INVALID")
      {:error, :invalid}
    end
  end
end
