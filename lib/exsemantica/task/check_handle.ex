defmodule Exsemantica.Task.CheckHandle do
  @moduledoc """
  A task that transforms handles of users or aggregates
  """
  @behaviour Exsemantica.Task

  @impl true
  def run(%{raw: raw, type: :aggregate}) do
    case Exsemantica.Constrain.into_valid_aggregate(raw) do
      {:ok, transformed} ->
        {:ok, %{identical?: transformed == raw, transformed: transformed}}

      :error ->
        :error
    end
  end

  @impl true
  def run(%{raw: raw, type: :username}) do
    case Exsemantica.Constrain.into_valid_username(raw) do
      {:ok, transformed} ->
        {:ok, %{identical?: transformed == raw, transformed: transformed}}

      :error ->
        :error
    end
  end
end
