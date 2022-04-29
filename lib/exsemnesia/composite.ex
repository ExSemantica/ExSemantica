defmodule Exsemnesia.Composite do
  @moduledoc """
  Defines functions that do many transactions.

  None of these functions validate the handles because the functions before them
  validated them. Be careful.
  """
  @doc """
  Puts a user into the database. Does NOT validate the handle.
  """
  def raw_put_user(handle, hash) do
    idx = Exsemnesia.Utils.increment(:node_count)
    stamp = DateTime.utc_now()

    [
      Exsemnesia.Utils.put(:users, {:users, idx, stamp, handle, <<0::128>>}, {idx, handle}),
      Exsemnesia.Utils.put(:auth, {:auth, String.downcase(handle, :ascii), hash, nil, stamp |> DateTime.add(Exsemnesia.Auth.get_backoff())})
    ]
    |> Exsemnesia.Database.transaction("put user into database")
  end

  @doc """
  Puts a post into the database. Does NOT validate the handle.
  """
  def raw_put_post(handle, title, content, posted_by) do
    idx = Exsemnesia.Utils.increment(:node_count)
    stamp = DateTime.utc_now()

    [
      Exsemnesia.Utils.put(
        :posts,
        {:posts, idx, stamp, handle, title, content, posted_by},
        {idx, handle}
      )
    ]
    |> Exsemnesia.Database.transaction("put post into database")
  end

  @doc """
  Puts a post into the database. Does NOT validate the handle.
  """
  def raw_put_interest(handle, title, content, related_to) do
    idx = Exsemnesia.Utils.increment(:node_count)
    stamp = DateTime.utc_now()

    [
      Exsemnesia.Utils.put(
        :interests,
        {:interests, idx, stamp, handle, title, content, related_to},
        {idx, handle}
      )
    ]
    |> Exsemnesia.Database.transaction("put interest into database")
  end
end
