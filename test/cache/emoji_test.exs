defmodule Crux.Cache.EmojiTest do
  use ExUnit.Case

  @cache Crux.Cache.Emoji

  doctest @cache

  @data %{
    "managed" => false,
    "name" => "b4nzy",
    "roles" => [],
    "user" => %{
      "username" => "spacebot",
      "discriminator" => "0234",
      "bot" => true,
      "id" => "242685080693243906",
      "avatar" => "0482e6a33b5a7a1d747b5aad093706b8"
    },
    "require_colons" => true,
    "animated" => false,
    "id" => "449983336790622248"
  }

  @updated_data %{@data | "name" => "b5nzy"}

  @struct @data |> Crux.Structs.create(Crux.Structs.Emoji)
  @updated_struct @updated_data |> Crux.Structs.create(Crux.Structs.Emoji)

  doctest @cache

  setup do
    sup = start_supervised!(@cache)

    [sup: sup]
  end

  setup do
    emoji = @cache.update(@data)

    [emoji: emoji]
  end

  test "inserting an emoji" do
    # done in setup
    assert @struct == @cache.fetch!(@struct.id)
  end

  test "updating an existing emoji" do
    @cache.update(@updated_data)

    assert @updated_struct == @cache.fetch!(@updated_struct.id)
  end

  test "deleting an existing emoji" do
    assert :ok == @cache.delete(@struct.id)

    assert :error == @cache.fetch(@struct.id)
  end

  test "deleting a non existing emoji" do
    assert :ok == @cache.delete(0)
  end
end
