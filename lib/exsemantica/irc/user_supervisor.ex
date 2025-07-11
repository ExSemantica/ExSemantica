defmodule Exsemantica.IRC.UserSupervisor do
  @moduledoc """
  User process supervisor.
  """
  use DynamicSupervisor

  @doc """
  Starts the user process supervisor.

  ## Arguments
  - max_children: The maximum amount of users the chat service can handle.
  """
  def start_link(args) do
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl true
  def init(%{max_children: max_children}) do
    DynamicSupervisor.init(max_children: max_children)
  end

  @doc """
  Tries to start a user process.
  """
  def start_child(args) do
    DynamicSupervisor.start_child(__MODULE__, {Exsemantica.IRC.UserProcess, args})
  end

  @doc """
  Shows how many user process there are.
  """
  def count_children() do
    Supervisor.count_children(__MODULE__)
  end
end
