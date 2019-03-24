defmodule Crux.Cache.PresenceTest do
  use ExUnit.Case

  @cache Crux.Cache.Presence

  doctest @cache

  @data %{
    "user" => %{"id" => "218348062828003328"},
    "status" => "online",
    "game" => nil,
    "client_status" => %{"desktop" => "online"},
    "activities" => [],
    "id" => "218348062828003328"
  }

  @updated_data %{@data | "status" => "dnd", "client_status" => %{"mobile" => "online"}}

  @struct @data |> Crux.Structs.create(Crux.Structs.Presence)
  @updated_struct @updated_data |> Crux.Structs.create(Crux.Structs.Presence)

  doctest @cache

  setup do
    sup = start_supervised!(@cache)

    [sup: sup]
  end

  setup do
    presence = @cache.update(@data)

    [presence: presence]
  end

  test "inserting a presence" do
    # done in setup
    assert @struct == @cache.fetch!(@struct.user)
  end

  test "updating an existing presence" do
    @cache.update(@updated_data)

    assert @updated_struct == @cache.fetch!(@updated_struct.user)
  end

  test "deleting an existing presence" do
    assert :ok == @cache.delete(@struct.user)

    assert :error == @cache.fetch(@struct.user)
  end

  test "deleting a non existing presence" do
    assert :ok == @cache.delete(0)
  end
end
