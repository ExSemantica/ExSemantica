defmodule Exsemnesia.Utils do
  @moduledoc """
  Utilities for the Mnesia database to make things easier.
  """
  require Exsemnesia.Handle128
  require Logger

  def increment(type) do
    cnt = :mnesia.dirty_update_counter(:counters, type, 1)
    <<cnt::128>>
  end

  def increment_popularity(table, idx) do
    %{
      operation: :rank,
      table: table,
      info: %{idx: idx, inc: 1}
    }
  end

  @doc """
  Counts how many items with this value for key in a table
  """
  def count(table, key, value) do
    %{
      operation: :count,
      table: table,
      info: %{key: key, value: value}
    }
  end

  @doc """
  Enumerates trends.
  """
  def trending(count) do
    %{
      operation: :tail,
      table: :ctrending,
      info: count
    }
  end

  def unique?(handle) do
    handle = String.downcase(handle, :ascii)

    {:atomic, uniqs} =
      [
        Exsemnesia.Utils.count(:lowercases, :lowercase, handle)
      ]
      |> Exsemnesia.Database.transaction("uniqueness")

    uniqs
    |> Enum.map(fn %{operation: :count, table: _table, info: _info, response: response} ->
      response
    end)
    |> Enum.sum() == 0
  end

  # ============================================================================
  # Get items
  # ============================================================================
  @doc """
  Gets an entry by its node ID.
  """
  def get(table, idx) do
    %{
      operation: :get,
      table: table,
      info: idx
    }
  end

  @doc """
  Indexes the real case
  """
  def get_real_case(lc_handle) do
    %{
      operation: :index,
      table: :lowercases,
      info: %{key: :lowercase, value: Exsemnesia.Handle128.serialize(lc_handle)}
    }
  end

  @doc """
  Looks up by handle. Only works with :users, :posts, and :interests tables.
  """
  def get_by_handle(table, handle) do
    %{
      operation: :index,
      table: table,
      info: %{key: :handle, value: handle}
    }
  end

  # ============================================================================
  # Put items
  # ============================================================================
  @doc """
  Puts an entry into a table.
  """
  def put(table, data) do
    %{
      operation: :get,
      table: table,
      info: data,
      idh: nil
    }
  end

  @doc """
  Puts an ID+handle composite entry into a table
  """
  def put(table, data, idh) do
    %{
      operation: :get,
      table: table,
      info: data,
      idh: idh
    }
  end
end
