defmodule Exsemantica.Gateway do
  @moduledoc """
  Namespace for interfacing with other applications by distributed Erlang.

  This includes the Sencha chat server.
  """
  use GenServer
  import Ecto.Query

  @doc """
  Starts the Gateway server
  """
  def start_link(_init_args) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Returns `:ok` only if the authentication data is a match.

  TODO: Hidden users should not match.
  """
  def user_ok?(username, password) do
    GenServer.call(__MODULE__, {:user_ok?, username, password})
  end

  @doc """
  Returns `:ok` only if the aggregate name is a match.

  TODO: Hidden aggregates should not match.
  """
  def aggregate_ok?(aggregate) do
    GenServer.call(__MODULE__, {:aggregate_ok?, aggregate})
  end

  # ===========================================================================
  @impl true
  def init(_init_args) do
    {:ok, []}
  end

  @impl true
  def handle_call({:user_ok?, username, password}, _from, state) do
    user_data =
      Exsemantica.Repo.one(
        from u in Exsemantica.Repo.User, where: ilike(u.username, ^username), select: u
      )

    case user_data do
      nil ->
        {:reply, {:error, :no_such_item}, state}

      %Exsemantica.Repo.User{username: true_username, password: hash, biography: biography} ->
        if Argon2.verify_pass(password, hash) do
          {:reply, {:ok, username: true_username, biography: biography}, state}
        else
          Argon2.no_user_verify()
          {:reply, {:error, :authentication_failed}, state}
        end
    end
  end

  @impl true
  def handle_call({:aggregate_ok?, aggregate}, _from, state) do
    aggregate_data =
      Exsemantica.Repo.one(
        from a in Exsemantica.Repo.Aggregate, where: ilike(a.name, ^aggregate), select: a
      )

    case aggregate_data do
      nil ->
        {:reply, {:error, :no_such_item}, state}

      %Exsemantica.Repo.Aggregate{name: true_aggregate, description: description} ->
        {:reply, {:ok, aggregate: true_aggregate, description: description}, state}
    end
  end
end
