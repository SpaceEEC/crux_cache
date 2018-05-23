defmodule Crux.Cache.Guild do
  @moduledoc """
    Default `Crux.Structs.Channel` cache.

    Unlike other caches this one splits up to different guild processes handling their data individually.
  """

  @behaviour Crux.Cache

  use GenServer

  @registry Crux.Cache.Guild.Registry

  alias Crux.Cache
  alias Crux.Cache.Guild.Supervisor, as: GuildSupervisor

  alias Crux.Structs.{Channel, Guild, Member, User, Role, VoiceState}

  @doc false
  def start_link(%Guild{id: id} = guild) do
    name = {:via, Registry, {@registry, id}}
    GenServer.start_link(__MODULE__, guild, name: name)
  end

  @doc """
    Looks up the `t:pid/0` of a `Crux.Cache.Guild`'s  `GenServer` by guild id.
  """
  @spec lookup(id :: integer()) :: {:ok, pid()} | :error
  def lookup(id) do
    with [{pid, _other}] <- Registry.lookup(@registry, id),
         true <- Process.alive?(pid) do
      {:ok, pid}
    else
      _ ->
        :error
    end
  end

  @doc """
    Inserts a:
    * `Crux.Structs.Guild` itself
    * `Crux.Structs.Member` in it
    * Chunk of `Crux.Structs.Member`
    * `Crux.Structs.Role`
    * `Crux.Structs.Member`'s roles
    * `Crux.Structs.VoiceState`
  """
  @spec insert(data :: term()) :: term()
  def insert({id, {:emojis, _emojis} = data}), do: do_cast(id, {:update, data})
  def insert(%Member{} = data), do: do_cast(data.guild_id, data)
  def insert({id, {:members, _members} = data}), do: do_cast(id, {:update, data})
  def insert(%Role{} = data), do: do_cast(data.guild_id, data)
  def insert(%Channel{} = data), do: do_cast(data.guild_id, data)
  # Presence / Role update
  def insert({id, {%User{}, _roles} = data}), do: do_cast(id, data)
  def insert(%VoiceState{} = data), do: do_cast(data.guild_id, data)
  def insert(%Guild{} = data), do: do_cast(data.id, data)

  @doc """
    Updates or inserts a:
    * `Crux.Structs.Guild` itself
    * `Crux.Structs.Member` in it
    * Chunk of `Crux.Structs.Member`
    * `Crux.Structs.Role`
    * `Crux.Structs.Member`'s roles
    * `Crux.Structs.VoiceState`
  """
  @spec update(data :: term()) :: term()
  def update({id, {:emojis, _emojis} = data}), do: do_call(id, {:update, data})
  def update(%Member{} = data), do: do_call(data.guild_id, data)
  def update({id, {:members, _members} = data}), do: do_call(id, {:update, data})
  def update(%Role{} = data), do: do_call(data.guild_id, data)
  def update(%Channel{} = data), do: do_call(data.guild_id, data)
  # Presence / Role update
  def update({id, {%User{}, _roles} = data}), do: do_call(id, data)
  def update(%VoiceState{} = data), do: do_call(data.guild_id, data)
  def update(%Guild{} = data), do: do_call(data.id, data)

  @doc """
    Deletes a guild.

    > This will remove all associated channels and emojis from the appropriate caches.
  """
  @spec delete(id :: integer()) :: :ok | :error
  def delete(id), do: do_call(id, {:delete, :remove})

  @doc """
    Deletes a:
    * `Crux.Structs.User` (effectively their `Crux.Structs.Member` and, if applicable, `Crux.Structs.VoiceState`)
    * `Crux.Structs.Role` from the guild
    * `Crux.Structs.Channel` from the guild
  """
  @spec delete(id :: integer(), data :: term()) :: :ok | :error
  def delete(id, data), do: do_call(id, {:delete, data})

  @doc """
  Fetches a guild from the cache by id.
  """
  @spec fetch(id :: integer()) :: {:ok, Guild.t()} | :error
  def fetch(id), do: with({:ok, pid} <- lookup(id), do: {:ok, GenServer.call(pid, :fetch)})

  @doc """
  Fetches a guild from the cache by id, raises if not found.
  """
  @spec fetch!(id :: integer()) :: Guild.t() | no_return()
  def fetch!(id) do
    with {:ok, guild} <- fetch(id) do
      guild
    else
      _ ->
        raise "Could not find a guild with the id #{id}"
    end
  end

  defp do_call(id, {atom, inner_data} = data) when is_atom(atom) do
    case lookup(id) do
      {:ok, pid} ->
        GenServer.call(pid, data)

      :error ->
        if match?(%Guild{}, inner_data) do
          GuildSupervisor.start_child(inner_data)
        else
          require Logger

          Logger.warn(
            "[Crux][Cache][Guild]: No process for guild #{inspect(id)}. Data: #{
              inspect(inner_data)
            }"
          )
        end

        data
    end
  end

  defp do_call(id, data), do: do_call(id, {:update, data})

  defp do_cast(id, {atom, inner_data} = data) when is_atom(atom) do
    case lookup(id) do
      {:ok, pid} ->
        GenServer.cast(pid, data)

      :error ->
        if match?(%Guild{}, inner_data) do
          GuildSupervisor.start_child(inner_data)
        else
          require Logger

          Logger.warn(
            "[Crux][Cache][Guild]: No process for guild #{id}. Data: #{inspect(inner_data)}"
          )
        end
    end

    data
  end

  defp do_cast(id, data), do: do_cast(id, {:update, data})

  def init(%Guild{} = guild), do: {:ok, guild}

  @doc false
  def handle_call(:fetch, _from, guild), do: {:reply, guild, guild}

  def handle_call({:update, {:emojis, emojis}}, _from, %{emojis: old_emojis} = guild) do
    new_emojis = MapSet.new(emojis, &Map.get(&1, :id))

    # Delete old emojis
    MapSet.difference(old_emojis, new_emojis)
    |> Enum.each(&Cache.emoji_cache().delete/1)

    {:reply, new_emojis, Map.put(guild, :emojis, new_emojis)}
  end

  def handle_call({:update, %Member{user: id} = member}, _from, %{members: members} = guild) do
    members = Map.update(members, id, %Crux.Structs.Member{}, &Map.merge(&1, member))
    guild = Map.put(guild, :members, members)

    {:reply, Map.get(members, id), guild}
  end

  def handle_call({:update, {:members, members}}, from, guild) do
    res =
      members
      |> Enum.reduce_while({%{}, guild}, fn member, {members, guild} ->
        case handle_call({:update, member}, from, guild) do
          {:reply, %Member{} = member, guild} ->
            members = Map.put(members, member.user, member)

            {:cont, {members, guild}}

          _ ->
            {:halt, nil}
        end
      end)

    case res do
      {members, %Guild{} = guild} when is_map(members) ->
        {:reply, members, guild}

      _ ->
        {:reply, :error, guild}
    end
  end

  def handle_call({:update, %Role{id: id} = role}, _from, guild) do
    guild = Map.update!(guild, :roles, &Map.put(&1, id, role))

    {:reply, role, guild}
  end

  def handle_call({:update, %Channel{id: id} = channel}, _from, guild) do
    guild = Map.update!(guild, :channels, &MapSet.put(&1, id))

    {:reply, channel, guild}
  end

  def handle_call({:update, {%User{id: id}, roles} = data}, _from, %{members: members} = guild) do
    guild =
      if Map.has_key?(members, id) do
        members = Map.update!(members, id, &Map.put(&1, :roles, roles))
        Map.put(guild, :members, members)
      else
        guild
      end

    {:reply, data, guild}
  end

  def handle_call({:update, %VoiceState{user_id: user_id} = voice_state}, _from, guild) do
    {:reply, voice_state, Map.update!(guild, :voice_states, &Map.put(&1, user_id, voice_state))}
  end

  def handle_call({:update, %Guild{} = new_guild}, _from, guild) do
    guild = Map.merge(guild, new_guild)

    {:reply, guild, guild}
  end

  def handle_call({:update, other}, _from, guild) do
    require Logger

    Logger.warn(
      "[Crux][Cache][Guild]: Received an unexpected insert or update: #{inspect(other)}"
    )

    {:reply, :error, guild}
  end

  def handle_call({:delete, %Role{id: role_id}}, _from, guild) do
    guild = Map.update!(guild, :roles, &Map.delete(&1, role_id))

    {:reply, :ok, guild}
  end

  def handle_call({:delete, %Channel{id: id}}, _from, guild) do
    guild = Map.update!(guild, :channels, &MapSet.delete(&1, id))
    Cache.channel_cache().delete(id)

    {:reply, :ok, guild}
  end

  def handle_call({:delete, %Member{user: user_id}}, _from, guild),
    do: delete_member(user_id, guild)

  def handle_call({:delete, %User{id: user_id}}, _from, guild), do: delete_member(user_id, guild)

  def handle_call({:delete, :remove}, _from, %{channels: channels, emojis: emojis}) do
    Enum.each(channels, &Cache.channel_cache().delete/1)
    Enum.each(emojis, &Cache.emoji_cache().delete/1)

    exit(:shutdown)
  end

  def handle_call({:delete, other}, _from, guild) do
    require Logger
    Logger.warn("[Crux][Cache][Guild]: Received an unexpected delete: #{inspect(other)}")

    {:reply, :error, guild}
  end

  @doc false
  def handle_cast(message, state) do
    state =
      case handle_call(message, nil, state) do
        {_, _, state} ->
          state

        {_, state} ->
          state

        _ ->
          state
      end

    {:noreply, state}
  end

  defp delete_member(user_id, guild) do
    guild =
      guild
      |> Map.update!(:members, &Map.delete(&1, user_id))
      |> Map.update!(:voice_states, &Map.delete(&1, user_id))

    {:reply, :ok, guild}
  end
end
