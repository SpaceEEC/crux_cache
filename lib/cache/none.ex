defmodule Crux.Cache.None do
  @moduledoc """
    Functions both as `Crux.Cache` and `Crux.Cache.Provider`

    As `Crux.Cache.Provider`: returning `Crux.Cache.None` for all caches.

    As `Crux.Cache`:
    * `cache` and `update` will always return the atomtified data.
    * `delete` is a noop and returns `:ok`
    * `fetch` is a noop and returns `:error`
    - `fetch!` is a noop and raises an error.
  """

  @behaviour Crux.Cache.Provider

  @doc "Returns `Crux.Cache.None`."
  @impl true
  def guild_cache(), do: __MODULE__
  @doc "Returns `Crux.Cache.None`."
  @impl true
  def channel_cache(), do: __MODULE__
  @doc "Returns `Crux.Cache.None`."
  @impl true
  def emoji_cache(), do: __MODULE__
  @doc "Returns `Crux.Cache.None`."
  @impl true
  def presence_cache(), do: __MODULE__
  @doc "Returns `Crux.Cache.None`."
  @impl true
  def user_cache(), do: __MODULE__

  alias Crux.Structs.Util

  @behaviour Crux.Cache

  @doc "Returns atomified data as is."
  @impl true
  def insert(data), do: data |> Util.atomify()
  @impl true
  @doc "Returns atomified data as is."
  def update(data), do: data |> Util.atomify()
  @impl true
  @doc "Is a noop returning `:ok`."
  def delete(_id), do: :ok
  @doc "Is a noop returning `:error`."
  @impl true
  def fetch(_id), do: :error
  @doc "Is a noop raising an error."
  @impl true
  def fetch!(_id), do: raise("#{__MODULE__} does not contain any structures.")
end
