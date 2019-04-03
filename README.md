# Crux.Cache

Library providing Discord API struct caches for crux.

## Useful links

 - [Documentation](https://hexdocs.pm/crux_cache/0.2.0/)
 - [Github](https://github.com/SpaceEEC/crux_cache/)
 - [Changelog](https://github.com/SpaceEEC/crux_cache/releases/tag/0.2.0/)
 - [Umbrella Development Documentation](https://crux.randomly.space/)


## Installation

The library can be installed by adding `crux_cache` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:crux_cache, "~> 0.2.0"}
  ]
end
```

## Usage

Small example:

```elixir
# Should be part of supervision tree
iex> {:ok, pid} = Crux.Cache.Default.start_link()
{:ok, #PID<0.178.0>}

iex(2)> Crux.Cache.User.insert(%{
...(2)>     "avatar" => "646a356e237350bf8b8dfde15667dfc4",
...(2)>     "discriminator" => "0001",
...(2)>     "id" => "218348062828003328",
...(2)>     "username" => "space"
...(2)>   }
...(2)> )
%{
  avatar: "646a356e237350bf8b8dfde15667dfc4",
  discriminator: "0001",
  id: 218348062828003328,
  username: "space"
}

iex(3)> Crux.Cache.User.fetch!(218348062828003328)
%Crux.Structs.User{
  avatar: "646a356e237350bf8b8dfde15667dfc4",
  bot: false,
  discriminator: "0001",
  id: 218348062828003328,
  username: "space"
}
```