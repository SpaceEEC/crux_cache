defmodule Crux.Cache.Guild.Supervisor do
  @moduledoc false
  use Supervisor

  @registry Crux.Cache.Guild.Registry

  def start_link(args), do: Supervisor.start_link(__MODULE__, args, name: __MODULE__)

  def init([cache_provider]) do
    [
      {Registry, keys: :unique, name: @registry},
      {Task, fn -> init_registry(cache_provider) end}
      |> Supervisor.child_spec(restart: :transient)
    ]
    |> Supervisor.init(strategy: :one_for_one)
  end

  defp init_registry(cache_provider) do
    Registry.register(@registry, :cache_provider, cache_provider)
  end

  def start_child(%Crux.Structs.Guild{} = guild) do
    [{_pid, cache_provider}] = Registry.lookup(@registry, :cache_provider)

    Supervisor.start_child(
      __MODULE__,
      Supervisor.child_spec(
        {Crux.Cache.Guild, {guild, cache_provider}},
        id: guild.id,
        restart: :transient
      )
    )
  end

  def guild_ids() do
    for {id, _, _, _} when is_integer(id) <- Supervisor.which_children(__MODULE__) do
      id
    end
  end
end
