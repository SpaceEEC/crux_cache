defmodule Crux.Cache.Guild.Registry do
  @moduledoc false

  use GenServer

  def start_link(args \\ []) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @spec guild_ids() :: [Crux.Rest.snowflake()]
  def guild_ids() do
    GenServer.call(__MODULE__, :ids)
  end

  @spec register_name(term(), pid()) :: :yes | :no
  def register_name(id, pid) do
    GenServer.call(__MODULE__, {:register, id, pid})
  end

  @spec unregister_name(term()) :: :ok
  def unregister_name(id) do
    GenServer.call(__MODULE__, {:unregister, id})
  end

  @spec whereis_name(term()) :: pid() | :undefined
  def whereis_name(id) do
    GenServer.call(__MODULE__, {:whereis, id})
  end

  @spec send(term(), term()) :: :ok
  def send(id, msg) do
    GenServer.call(__MODULE__, {:send, id, msg})
  end

  @impl true
  def init(args)
      when is_list(args)
      when is_map(args) do
    Process.flag(:trap_exit, true)
    state = Map.new(args)
    {:ok, state}
  end

  @impl true
  def handle_call(:ids, _from, state) do
    {:reply, Map.keys(state), state}
  end

  def handle_call({:register, id, pid}, _from, state) do
    case state do
      %{^id => _pid} ->
        {:reply, :no, state}

      _ ->
        Process.link(pid)
        {:reply, :yes, Map.put(state, id, pid)}
    end
  end

  def handle_call({:unregister, id}, _from, state) do
    state = Map.delete(state, id)

    {:reply, :ok, state}
  end

  def handle_call({:whereis, id}, _from, state) do
    {:reply, Map.get(state, id, :undefined), state}
  end

  def handle_call({:send, id, msg}, _from, state) do
    case state do
      %{^id => pid} -> Kernel.send(pid, msg)
      _ -> :erlang.error(:badarg, [{self(), id}, msg])
    end
  end

  def handle_call({:EXIT, pid, _reason}, state) do
    state =
      state
      |> Enum.filter(fn
        {_id, ^pid} -> false
        _ -> true
      end)
      |> Map.new()

    {:noreply, state}
  end
end
