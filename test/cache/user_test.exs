defmodule Crux.Cache.UserTest do
  use ExUnit.Case

  @cache Crux.Cache.User

  @data %{
    "avatar" => "646a356e237350bf8b8dfde15667dfc4",
    "discriminator" => "0001",
    "id" => "218348062828003328",
    "username" => "space"
  }
  @updated_data %{@data | "discriminator" => "0002", "username" => "space_but_updated"}

  @struct @data |> Crux.Structs.create(Crux.Structs.User)
  @updated_struct @updated_data |> Crux.Structs.create(Crux.Structs.User)

  doctest @cache

  setup do
    sup = start_supervised!(@cache)

    [sup: sup]
  end

  setup do
    user = @cache.update(@data)

    [user: user]
  end

  test "inserting a user" do
    # done in setup
    assert @struct == @cache.fetch!(@struct.id)
  end

  test "updating an existing user" do
    @cache.update(@updated_data)

    assert @updated_struct == @cache.fetch!(@updated_struct.id)
  end

  test "deleting an existing user" do
    assert :ok == @cache.delete(@struct.id)

    assert :error == @cache.fetch(@struct.id)
  end

  test "deleting a non existing user" do
    assert :ok == @cache.delete(0)
  end
end
