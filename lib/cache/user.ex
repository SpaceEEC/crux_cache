defmodule Crux.Cache.User do
  @moduledoc """
    Default `Crux.Structs.User` cache.

    Difference opposed to "regular" base caches.
    - Has `me/0`, `me!/0` and `me/1` functions to specify or retrieve the own user.
  """
  use Crux.Cache.Base, struct: Crux.Structs.User

  @doc """
    Fetches the own user.
  """
  @spec me() :: {:ok, Crux.Structs.User.t()} | :error
  def me, do: GenServer.call(@name, :me) |> fetch()

  @doc """
    Sets the id of the own user, the data itself has to be inserted into the cache like usual.
  """
  @spec me(id :: integer()) :: integer()
  def me(id), do: GenServer.call(@name, {:me, id})

  @doc """
    Fetches the own user, raises if not cached.
  """
  @spec me!() :: Crux.Structs.User.t() | no_return()
  def me!, do: GenServer.call(@name, :me) |> fetch!()

  @doc false
  @impl true
  def handle_call(:me, _from, %{me: id} = state), do: {:reply, id, state}
  def handle_call(:me, _from, state), do: {:reply, :error, state}

  def handle_call({:me, id}, _from, state), do: {:reply, id, Map.put(state, :me, id)}
  def handle_call(message, from, state), do: super(message, from, state)
end
