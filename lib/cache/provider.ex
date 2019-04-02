defmodule Crux.Cache.Provider do
  @moduledoc """
    A behaviour module for cache providers.
  """

  @doc """
    Fetches the module handling the guild cache.
  """
  @callback guild_cache() :: module()

  @doc """
    Fetches the module handling the channel cache.
  """
  @callback channel_cache() :: module()

  @doc """
    Fetches the module handling the channel cache.
  """
  @callback emoji_cache() :: module()

  @doc """
    Fetches the module handling the presence cache.
  """
  @callback presence_cache() :: module()

  @doc """
    Fetches the module handling the user cache.
  """
  @callback user_cache() :: module()

  defmacro __using__(_) do
    quote location: :keep do
      @behaviour unquote(__MODULE__)

      @doc false
      use Supervisor

      @doc false
      @spec start_link(term(), GenServer.options()) :: Supervisor.on_start()
      def start_link(arg \\ [], opts \\ []) do
        Supervisor.start_link(__MODULE__, arg, opts)
      end

      @impl true
      def init(_) do
        children =
          [:guild_cache, :channel_cache, :emoji_cache, :presence_cache, :user_cache]
          |> Enum.map(&apply(__MODULE__, &1, []))
          |> Enum.filter(fn mod -> mod.__info__(:functions)[:start_link] end)

        Supervisor.init(children, strategy: :one_for_one)
      end

      defoverridable(init: 1, start_link: 2)
    end
  end
end
