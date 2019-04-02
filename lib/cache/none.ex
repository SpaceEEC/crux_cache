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
  @spec guild_cache() :: module()
  def guild_cache(), do: __MODULE__
  @doc "Returns `Crux.Cache.None`."
  @impl true
  @spec channel_cache() :: module()
  def channel_cache(), do: __MODULE__
  @doc "Returns `Crux.Cache.None`."
  @impl true
  @spec emoji_cache() :: module()
  def emoji_cache(), do: __MODULE__
  @doc "Returns `Crux.Cache.None`."
  @impl true
  @spec presence_cache() :: module()
  def presence_cache(), do: __MODULE__
  @doc "Returns `Crux.Cache.None`."
  @impl true
  @spec user_cache() :: module()
  def user_cache(), do: __MODULE__

  alias Crux.Structs.Util

  @behaviour Crux.Cache

  @doc "Returns atomified data as is."
  @impl true
  @spec insert(term()) :: term()
  def insert(data), do: Util.atomify(data)
  @doc "Returns atomified data as is."
  @impl true
  @spec update(term()) :: term()
  def update(data), do: Util.atomify(data)
  @doc "Is a noop returning `:ok`."
  @impl true
  @spec delete(Crux.Cache.key()) :: :ok
  def delete(_id), do: :ok
  @doc "Is a noop returning `:error`."
  @impl true
  @spec fetch(Crux.Cache.key()) :: :error
  def fetch(_id), do: :error
  @doc "Is a noop raising an error."
  @spec fetch!(Crux.Cache.key()) :: no_return()
  @impl true
  def fetch!(_id), do: raise("#{__MODULE__} does not contain any structures.")
end
