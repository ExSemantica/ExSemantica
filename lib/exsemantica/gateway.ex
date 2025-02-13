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

  # ===========================================================================
  @impl true
  def init(_init_args) do
    {:ok, []}
  end

  @impl true
  def handle_cast({:user_info, other, username, password}, state) do
    user_data =
      Exsemantica.Repo.one(
        from u in Exsemantica.Repo.User, where: ilike(u.username, ^username), select: u
      )

    case user_data do
      nil ->
        send(other, {__MODULE__, Node.self(), {:user_info, {:error, :no_such_item}}})

      %Exsemantica.Repo.User{username: true_username, password: hash} ->
        if Argon2.verify_pass(password, hash) do
          send(
            other,
            {__MODULE__, Node.self(),
             {:user_info, {:ok, %{username: true_username}}}}
          )
        else
          Argon2.no_user_verify()

          send(
            other,
            {__MODULE__, Node.self(), {:user_info, {:error, :authentication_failed}}}
          )
        end
    end

    {:noreply, state}
  end

  @impl true
  def handle_cast({:aggregate_info, other, aggregate}, state) do
    aggregate_data =
      Exsemantica.Repo.one(
        from a in Exsemantica.Repo.Aggregate, where: ilike(a.name, ^aggregate), select: a
      )

    case aggregate_data do
      nil ->
        send(other, {__MODULE__, Node.self(), {:aggregate_info, {:error, :no_such_item}}})

      %Exsemantica.Repo.Aggregate{
        name: true_aggregate,
        description: description,
        inserted_at: inserted_at
      } ->
        send(
          other,
          {__MODULE__, Node.self(),
           {:aggregate_info,
            {:ok,
             %{aggregate: true_aggregate, description: description, inserted_at: inserted_at}}}}
        )
    end

    {:noreply, state}
  end

  @impl true
  def handle_cast({:ping, other}, state) do
    send(other, {__MODULE__, Node.self(), :pong})

    {:noreply, state}
  end
end
