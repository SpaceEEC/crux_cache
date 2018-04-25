defmodule Crux.Cache.Application do
  @moduledoc false

  alias Crux.Cache

  use Application

  @doc false
  def start(_type, _args) do
    children =
      []
      |> maybe_supervise(:guild, Cache.Guild.Supervisor)
      |> maybe_supervise(:channel, Cache.Channel)
      |> maybe_supervise(:emoji, Cache.Emoji)
      |> maybe_supervise(:presence, Cache.Presence)
      |> maybe_supervise(:user, Cache.User)

    Supervisor.start_link(children, strategy: :one_for_one, name: Crux.Cache.Supervisor)
  end

  @doc false
  def maybe_supervise(acc, name, default) do
    case Application.fetch_env(:crux_cache, name) do
      :error ->
        [default | acc]

      {:ok, module} when is_atom(module) ->
        if Keyword.has_key?(module.__info__(:functions), :start_link),
          do: [module | acc],
          else: acc
    end
  end
end
