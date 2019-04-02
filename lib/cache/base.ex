defmodule Crux.Cache.Base do
  @moduledoc """
    Base cache utilising ETS tables, `:ets`
  """

  alias Crux.Structs
  alias Crux.Structs.Util

  defmacro __using__(args \\ []) do
    # This does not feel right
    quote location: :keep do
      use GenServer

      @behaviour Crux.Cache

      @name __MODULE__
      @struct unquote(args[:struct])

      @spec start_link(args :: term) :: GenServer.on_start()
      def start_link(args \\ []), do: GenServer.start_link(__MODULE__, %{}, name: @name)

      @spec insert(data :: term()) :: term()
      def insert(data), do: Crux.Cache.Base.cache(@name, data)

      @spec update(data :: term()) :: term()
      def update(data), do: Crux.Cache.Base.update(@name, data)

      @spec delete(id :: Crux.Cache.key()) :: :ok
      def delete(id), do: Crux.Cache.Base.delete(@name, id)

      @spec fetch(id :: Crux.Cache.key()) :: {:ok, term()} | :error
      @spec fetch!(id :: identifier()) :: {:ok, term()} | :error

      if @struct do
        def fetch(id) do
          with {:ok, data} <- Crux.Cache.Base.fetch(@name, id),
               do: {:ok, Structs.create(data, @struct)}
        end

        def fetch!(id) do
          @name
          |> Crux.Cache.Base.fetch!(id)
          |> Structs.create(@struct)
        end
      else
        def fetch(id), do: Crux.Cache.Base.fetch(@name, id)
        def fetch!(id), do: Crux.Cache.Base.fetch!(@name, id)
      end

      @doc false
      @impl true
      def init(args) do
        :ets.new(@name, [:named_table, read_concurrency: true])

        {:ok, args}
      end

      @doc false
      @impl true
      def handle_cast({:cache, structure}, state) do
        {_, _, state} = handle_call({:update, structure}, nil, state)

        {:noreply, state}
      end

      @doc false
      @impl true
      def handle_call({:update, structure}, _from, state) do
        structure =
          case Crux.Cache.Base.fetch(@name, structure.id) do
            {:ok, oldstruct} ->
              structure = Crux.Cache.Base.deep_merge(oldstruct, structure)

            :error ->
              structure
          end

        :ets.insert(@name, {structure.id, structure})

        {:reply, structure, state}
      end

      @doc false
      def handle_call({:delete, id}, _from, state) do
        :ets.delete(@name, id)

        {:reply, :ok, state}
      end

      defoverridable start_link: 1,
                     insert: 1,
                     update: 1,
                     delete: 1,
                     fetch: 1,
                     fetch!: 1,
                     init: 1,
                     handle_call: 3
    end
  end

  @doc false
  @spec cache(GenServer.server(), map() | struct()) :: map() | struct()
  def cache(name, structure) do
    structure =
      structure
      |> Util.atomify()
      |> Map.update!(:id, &Util.id_to_int/1)

    GenServer.cast(name, {:cache, structure})

    structure
  end

  @doc false
  @spec update(GenServer.server(), map() | struct()) :: map() | struct()
  def update(name, structure) do
    structure =
      structure
      |> Util.atomify()
      |> Map.update!(:id, &Util.id_to_int/1)

    GenServer.call(name, {:update, structure})
  end

  @doc false
  @spec fetch(GenServer.server(), Crux.Cache.key()) :: {:ok, struct()} | :error
  def fetch(name, id) do
    case :ets.lookup(name, id) do
      [{^id, structure}] ->
        {:ok, structure}

      _ ->
        :error
    end
  end

  @doc false
  @spec fetch!(GenServer.server(), Crux.Cache.key()) :: struct() | no_return()
  def fetch!(name, id) do
    case fetch(name, id) do
      {:ok, structure} ->
        structure

      _ ->
        raise "Could not find #{inspect(id)} in #{name}"
    end
  end

  @doc false
  @spec delete(GenServer.server(), Crux.Cache.key()) :: :ok
  def delete(name, id) do
    case fetch(name, id) do
      {:ok, _} ->
        GenServer.call(name, {:delete, id})

      :error ->
        :ok
    end
  end

  @doc false
  @spec deep_merge(term(), term()) :: term()
  def deep_merge(%{} = old, %{} = new), do: Map.merge(old, new, &deep_merge_map/3)

  # Replacing lists seems to be the correct way to "update" here
  def deep_merge(old, new) when is_list(old) and is_list(new), do: new
  def deep_merge(_old, new), do: new

  @doc false
  @spec deep_merge_map(term(), term(), term()) :: term()
  def deep_merge_map(_key, %{} = old_v, new_v) when is_list(new_v), do: deep_merge(old_v, new_v)

  # Replacing lists seems to be the correct way to "update" here
  def deep_merge_map(_key, old_v, new_v) when is_list(old_v) and is_list(new_v), do: new_v
  def deep_merge_map(_key, _oldV, new_v), do: new_v
end
