defmodule Crux.Cache.Default do
  @moduledoc """
    A provider using the default caches:
    * `Crux.Cache.Guild`
    * `Crux.Cache.Channel`
    * `Crux.Cache.Emoji`
    * `Crux.Cache.Presence`
    * `Crux.Cache.User`
  """
  alias Crux.Cache

  use Cache.Provider

  def init(_) do
    children = [
      Cache.Guild.Supervisor.Supervisor,
      Cache.Channel,
      Cache.Emoji,
      Cache.Presence,
      Cache.User
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  @doc """
    The default guild cache.
  """
  @impl true
  @spec guild_cache() :: module()
  def guild_cache(), do: Cache.Guild

  @doc """
  The default guild cache: `Crux.Cache.Channel`.
  """
  @impl true
  @spec channel_cache() :: module()
  def channel_cache(), do: Cache.Channel

  @doc """
    The default guild cache: `Crux.Cache.Emoji`.
  """
  @impl true
  @spec emoji_cache() :: module()
  def emoji_cache(), do: Cache.Emoji

  @doc """
    The default guild cache: `Crux.Cache.Presence`.
  """
  @impl true
  @spec presence_cache() :: module()
  def presence_cache(), do: Cache.Presence

  @doc """
    The default guild cache: `Crux.Cache.User`.
  """
  @impl true
  @spec user_cache() :: module()
  def user_cache(), do: Cache.User
end
