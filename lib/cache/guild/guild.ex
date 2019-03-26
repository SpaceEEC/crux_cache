defmodule Crux.Cache.Guild do
  @moduledoc """
    Default `Crux.Structs.Channel` cache.

    Unlike other caches this one splits up to different guild processes handling their data individually.
  """

  @behaviour Crux.Cache

  @provider Crux.Cache.Default

  use GenServer

  alias Crux.Cache.Guild.Supervisor, as: GuildSupervisor
  alias Crux.Cache.Guild.Registry

  alias Crux.Structs.{Channel, Guild, Member, User, Role, VoiceState}

  @doc false
  def start_link(%Guild{id: guild_id} = guild) do
    name = {:via, Registry, guild_id}
    GenServer.start_link(__MODULE__, guild, name: name)
  end

  @doc """
    Looks up the `t:pid/0` of a `Crux.Cache.Guild`'s `GenServer` by guild id.
  """
  @spec lookup(guild_id :: Crux.Rest.snowflake()) :: {:ok, pid()} | :error
  def lookup(guild_id) do
    with pid when is_pid(pid) <- Registry.whereis_name(guild_id),
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
  def insert({guild_id, {:emojis, _emojis} = data}), do: do_cast(guild_id, {:update, data})
  def insert(%Member{} = data), do: do_cast(data.guild_id, data)
  def insert({guild_id, {:members, _members} = data}), do: do_cast(guild_id, {:update, data})
  def insert(%Role{} = data), do: do_cast(data.guild_id, data)
  def insert(%Channel{} = data), do: do_cast(data.guild_id, data)
  # Presence / Role update
  def insert({guild_id, {%User{}, _roles} = data}), do: do_cast(guild_id, data)
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
  def update({guild_id, {:emojis, _emojis} = data}), do: do_call(guild_id, {:update, data})
  def update(%Member{} = data), do: do_call(data.guild_id, data)
  def update({guild_id, {:members, _members} = data}), do: do_call(guild_id, {:update, data})
  def update(%Role{} = data), do: do_call(data.guild_id, data)
  def update(%Channel{} = data), do: do_call(data.guild_id, data)
  # Presence / Role update
  def update({guild_id, {%User{}, _roles} = data}), do: do_call(guild_id, data)
  def update(%VoiceState{} = data), do: do_call(data.guild_id, data)
  def update(%Guild{} = data), do: do_call(data.id, data)

  @doc """
    Deletes a:
    * `Crux.Structs.Member` (if applicable, also their `Crux.Structs.VoiceState`) from the guild
    * `Crux.Structs.Role` from the guild
    * `Crux.Structs.Channel` from the guild
    * `Crux.Structs.Guild` itself
      > This will remove all associated channels and emojis from the appropriate caches.
  """
  @spec delete(
          data_or_id ::
            Crux.Rest.snowflake()
            | Crux.Structs.Guild.t()
            | Crux.Structs.Channel.t()
            | Crux.Structs.Role.t()
            | Crux.Structs.Member.t()
        ) :: :ok
  def delete(data_or_id) do
    {guild_id, data} =
      case data_or_id do
        guild_id when is_number(guild_id) ->
          {guild_id, :remove}

        %Guild{id: guild_id} ->
          {guild_id, :remove}

        %Channel{guild_id: guild_id} = channel ->
          {guild_id, channel}

        %Role{guild_id: guild_id} = role ->
          {guild_id, role}

        %Member{guild_id: guild_id} = member ->
          {guild_id, member}
      end

    case lookup(guild_id) do
      {:ok, pid} ->
        GenServer.call(pid, {:delete, data})

      :error ->
        :ok
    end
  end

  @doc """
  Fetches a guild from the cache by id.
  """
  @spec fetch(guild_id :: Crux.Rest.snowflake()) :: {:ok, Guild.t()} | :error
  def fetch(guild_id),
    do: with({:ok, pid} <- lookup(guild_id), do: {:ok, GenServer.call(pid, :fetch)})

  @doc """
  Fetches a guild from the cache by id, raises if not found.
  """
  @spec fetch!(guild_id :: Crux.Rest.snowflake()) :: Guild.t() | no_return()
  def fetch!(guild_id) do
    with {:ok, guild} <- fetch(guild_id) do
      guild
    else
      _ ->
        raise "Could not find a guild with the id #{inspect(guild_id)} in the cache."
    end
  end

  defp do_call(guild_id, {atom, inner_data} = data) when is_atom(atom) do
    case lookup(guild_id) do
      {:ok, pid} ->
        GenServer.call(pid, data)

      :error ->
        if match?(%Guild{}, inner_data) do
          GuildSupervisor.start_child(inner_data)
        else
          require Logger

          Logger.warn(fn ->
            "[Crux][Cache][Guild]: No process for guild #{inspect(guild_id)}." <>
              "Data: #{inspect(inner_data)}"
          end)
        end

        inner_data
    end
  end

  defp do_call(guild_id, data), do: do_call(guild_id, {:update, data})

  defp do_cast(guild_id, {atom, inner_data} = data) when is_atom(atom) do
    case lookup(guild_id) do
      {:ok, pid} ->
        GenServer.cast(pid, data)

      :error ->
        if match?(%Guild{}, inner_data) do
          GuildSupervisor.start_child(inner_data)
        else
          require Logger

          Logger.warn(fn ->
            "[Crux][Cache][Guild]: No process for guild #{inspect(guild_id)}." <>
              " Data: #{inspect(inner_data)}"
          end)
        end
    end

    :ok
  end

  defp do_cast(guild_id, data), do: do_cast(guild_id, {:update, data})

  def init(%Guild{} = guild), do: {:ok, guild}

  @doc false
  def handle_call(:fetch, _from, guild), do: {:reply, guild, guild}

  def handle_call(
        {:update, {:emojis, emojis}},
        _from,
        %{emojis: old_emojis} = guild
      ) do
    new_emojis = MapSet.new(emojis, &Map.get(&1, :id))

    # Delete old emojis
    MapSet.difference(old_emojis, new_emojis)
    |> Enum.each(&@provider.emoji_cache().delete/1)

    state = %{guild | emojis: new_emojis}

    {:reply, new_emojis, state}
  end

  def handle_call(
        {:update, %Member{user: user_id} = member},
        _from,
        %{members: members} = guild
      ) do
    members =
      case members do
        %{^user_id => old_member} ->
          %{members | user_id => Map.merge(old_member, member)}

        _ ->
          Map.put(members, user_id, member)
      end

    state = %{guild | members: members}

    {:reply, Map.get(members, user_id), state}
  end

  def handle_call(
        {:update, {:members, members}},
        from,
        guild
      ) do
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

  def handle_call(
        {:update, %Role{id: role_id} = role},
        _from,
        %{roles: roles} = guild
      ) do
    state = %{guild | roles: Map.put(roles, role_id, role)}

    {:reply, role, state}
  end

  def handle_call(
        {:update, %Channel{id: channel_id} = channel},
        _from,
        %{channels: channels} = guild
      ) do
    guild = %{guild | channels: MapSet.put(channels, channel_id)}
    state = guild

    {:reply, channel, state}
  end

  def handle_call(
        {:update, {%User{id: user_id}, roles} = data},
        _from,
        %{members: members} = guild
      ) do
    state =
      case members do
        %{^user_id => member} ->
          member = %{member | roles: roles}
          members = %{members | user_id => member}
          %{guild | members: members}

        _ ->
          guild
      end

    {:reply, data, state}
  end

  def handle_call(
        {:update, %VoiceState{user_id: user_id} = voice_state},
        _from,
        %{voice_states: voice_states} = guild
      ) do
    voice_states = Map.put(voice_states, user_id, voice_state)
    state = %{guild | voice_states: voice_states}

    {:reply, voice_state, state}
  end

  def handle_call({:update, %Guild{} = new_guild}, _from, guild) do
    state = Map.merge(guild, new_guild)

    {:reply, guild, state}
  end

  def handle_call({:update, other}, _from, state) do
    require Logger

    Logger.warn(fn ->
      "[Crux][Cache][Guild]: Received an unexpected insert or update: #{inspect(other)}"
    end)

    {:reply, :error, state}
  end

  def handle_call(
        {:delete, %Role{id: role_id}},
        _from,
        %{roles: roles} = guild
      ) do
    state = %{guild | roles: Map.delete(roles, role_id)}

    {:reply, :ok, state}
  end

  def handle_call(
        {:delete, %Channel{id: channel_id}},
        _from,
        %{channels: channels} = guild
      ) do
    state = %{guild | channels: MapSet.delete(channels, channel_id)}
    @provider.channel_cache().delete(channel_id)

    {:reply, :ok, state}
  end

  def handle_call({:delete, %Member{user: user_id}}, _from, state),
    do: delete_member(user_id, state)

  def handle_call({:delete, %User{id: user_id}}, _from, state), do: delete_member(user_id, state)

  def handle_call(
        {:delete, :remove},
        _from,
        %{channels: channels, emojis: emojis} = state
      ) do
    Enum.each(channels, &@provider.channel_cache().delete/1)
    Enum.each(emojis, &@provider.emoji_cache().delete/1)

    {:stop, :shutdown, :ok, state}
  end

  def handle_call({:delete, other}, _from, state) do
    require Logger

    Logger.warn(fn -> "[Crux][Cache][Guild]: Received an unexpected delete: #{inspect(other)}" end)

    {:reply, :ok, state}
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

  defp delete_member(
         user_id,
         %{members: members, voice_states: voice_states} = guild
       ) do
    state = %{
      guild
      | members: Map.delete(members, user_id),
        voice_states: Map.delete(voice_states, user_id)
    }

    {:reply, :ok, state}
  end
end
