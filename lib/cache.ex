defmodule Crux.Cache do
  @moduledoc """
    Behaviour all caches must implement. (Looking at custom ones you may want to write)

    There are exceptions:
    * User cache:
      * Implement a `me/1` function setting the own user id
      * A `me/0` and `me!/0` function getting the own user
    * Guild cache:
      * A bit more, you probably want to take a look at the code of the `Crux.Cache.Guild` module

    Custom caches should be put under a `Crux.Cache.Provider`. (Can be combined with default caches)

    Also worth a look:
    * `Crux.Cache.None` - A dummy `Crux.Cache` and `Crux.Cache.Provider`, not caching anything.
  """

  @typedoc """
  Default caches are using Discord Snowflakes as identifiers.
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
  """
  @callback delete(id :: key()) :: :ok

  @doc """
  Fetches data from the cache by key.
  """
  @callback fetch(id :: key()) :: {:ok, term()} | :error

  @doc """
  Fetches data from the cache by key, raises if not found.
  """
  @callback fetch!(id :: identifier()) :: term() | no_return()

  @optional_callbacks start_link: 1
end
