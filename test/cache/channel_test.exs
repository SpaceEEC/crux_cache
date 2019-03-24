defmodule Crux.Cache.ChannelTest do
  use ExUnit.Case

  @cache Crux.Cache.Channel

  doctest @cache

  @data %{
    "guild_id" => "243175181885898762",
    "name" => "testing_text",
    "permission_overwrites" => [
      %{
        "deny" => 0,
        "type" => "role",
        "id" => "243175181885898762",
        "allow" => 0
      }
    ],
    "last_pin_timestamp" => "2019-02-23T13:39:00.178000+00:00",
    "topic" => "test things",
    "parent_id" => "355984291081224202",
    "nsfw" => false,
    "position" => 12,
    "rate_limit_per_user" => 1,
    "last_message_id" => "558693382927548466",
    "type" => 0,
    "id" => "250372608284033025"
  }

  @updated_data %{@data | "name" => "testing_news", "type" => 5}

  @struct @data |> Crux.Structs.create(Crux.Structs.Channel)
  @updated_struct @updated_data |> Crux.Structs.create(Crux.Structs.Channel)

  doctest @cache

  setup do
    sup = start_supervised!(@cache)

    [sup: sup]
  end

  setup do
    channel = @cache.update(@data)

    [channel: channel]
  end

  test "inserting a channel" do
    # done in setup
    assert @struct == @cache.fetch!(@struct.id)
  end

  test "updating an existing channel" do
    @cache.update(@updated_data)

    assert @updated_struct == @cache.fetch!(@updated_struct.id)
  end

  test "deleting an existing channel" do
    assert :ok == @cache.delete(@struct.id)

    assert :error == @cache.fetch(@struct.id)
  end

  test "deleting a non existing channel" do
    assert :ok == @cache.delete(0)
  end
end
