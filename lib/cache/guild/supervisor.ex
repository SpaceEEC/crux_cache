defmodule Crux.Cache.Guild.Supervisor.Supervisor do
  @moduledoc false
  use Supervisor

  @spec start_link(term()) :: Supervisor.on_start()
  def start_link(opts), do: Supervisor.start_link(__MODULE__, opts, name: __MODULE__)

  @impl true
  def init(_opts) do
    children = [
      Crux.Cache.Guild.Registry,
      Crux.Cache.Guild.Supervisor
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end

defmodule Crux.Cache.Guild.Supervisor do
  @moduledoc false
  use DynamicSupervisor

  @spec start_link(term()) :: DynamicSupervisor.on_start()
  def start_link(args), do: DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)

  @impl true
  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @spec start_child(Crux.Structs.Guild.t()) :: DynamicSupervisor.on_start_child()
  def start_child(%Crux.Structs.Guild{} = guild) do
    DynamicSupervisor.start_child(
      __MODULE__,
      Supervisor.child_spec(
        {Crux.Cache.Guild, guild},
        id: guild.id,
        restart: :transient
      )
    )
  end
end
