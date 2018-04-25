defmodule Crux.Cache do
  @moduledoc """
    Behaviour all caches must implement. (Looking at custom ones you may want to write)

    There are exceptions:
    * User cache:
      * Implement a `me/1` function setting the own user id
      * A `me/0` and `me!/0` function getting the own user
    * Guild cache:
      * A bit more, you probably want to take a look at the code of the `Crux.Cache.Guild` module
  """

  @typedoc """
  Default caches are using Discord Snowflakes as identifiers.

  Custom caches my obviously implement their own key type.
  """
  @type key :: non_neg_integer()

  @doc """
  Used to start anything fitting under a supervision tree, like for example a `GenServer`, instructed with handling the cache.

  Optional, you maybe want to use external caching, e.g. Redis, not requiring anything like that.
  """
  @callback start_link(args :: term()) :: Supervisor.on_start()

  @doc """
  Inserts data into the cache.

  Returns the atomified data allowing the operation to be chained.

  For example something like that:
  ```elixir
  id =
    raw_data
    |> Cache.insert()
    |> Map.get(:id)
  ```
  """
  @callback insert(data :: term()) :: term()

  @doc """
  Inserts data into the cache.

  Returns "updated" data including changes by merging.
  For example from a message embed update to a full message object

  ```elixir
  content =
    partial_message # only contains `:id`, `:channel_id`, and `:embeds`
    |> Cache.update()
    |> Map.get(:content) # present if the message was cached previously
  ```
  """
  @callback update(data :: term()) :: term()

  @doc """
  Deletes data from the cache by key.

  Always returns `:ok`, even when the key did not exist.
  """
  @callback delete(id :: key()) :: :ok

  @doc """
  Fetches data from the cache by key.
  """
  @callback fetch(id :: key()) :: {:ok, term()} | :error

  @doc """
  Fetches data from the cache by key, raises if not found.
  """
  @callback fetch!(id :: identifier()) :: term() | :error

  @optional_callbacks start_link: 1

  @doc """
    Fetches the module handling the guild caching.

    Defaults to `Crux.Cache.Guild`.
  """
  @spec guild_cache() :: module()
  def guild_cache(), do: Application.get_env(:crux_cache, :guild, Crux.Cache.Guild)

  @doc """
    Fetches the module handling the guild cache.

    Defaults to `Crux.Cache.Channel`.
  """
  @spec channel_cache() :: module()
  def channel_cache(), do: Application.get_env(:crux_cache, :channel, Crux.Cache.Channel)

  @doc """
    Fetches the module handling the emoji cache.

    Defaults to `Crux.Cache.Emoji`.
  """
  @spec emoji_cache() :: module()
  def emoji_cache(), do: Application.get_env(:crux_cache, :emoji, Crux.Cache.Emoji)

  @doc """
    Fetches the module handling the presence cache.

    Defaults to `Crux.Cache.Presence`.
  """
  @spec presence_cache() :: module()
  def presence_cache(), do: Application.get_env(:crux_cache, :presence, Crux.Cache.Presence)

  @doc """
    Fetches the module handling the user cache.

    Defaults to `Crux.Cache.User`.
  """
  @spec user_cache() :: module()
  def user_cache(), do: Application.get_env(:crux_cache, :user, Crux.Cache.User)
end
