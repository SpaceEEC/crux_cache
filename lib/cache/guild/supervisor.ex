defmodule Crux.Cache.Guild.Supervisor do
  @moduledoc false
  use Supervisor

  @registry Crux.Cache.Guild.Registry

  def start_link(args), do: Supervisor.start_link(__MODULE__, args, name: __MODULE__)

  def init(_args) do
    [{Registry, keys: :unique, name: @registry}]
    |> Supervisor.init(strategy: :one_for_one)
  end

  def start_child(%Crux.Structs.Guild{} = guild) do
    Supervisor.start_child(
      __MODULE__,
      Supervisor.child_spec(
        {Crux.Cache.Guild, guild},
        id: guild.id,
        # TODO: Maybe permanent, although everything resets to default when an error occurs
        restart: :transient
      )
    )
  end

  def guild_ids do
    Supervisor.which_children(__MODULE__)
    |> Enum.map(fn {_, pid, _, _} ->
      Registry.keys(@registry, pid)
      |> List.first()
    end)
  end
end
