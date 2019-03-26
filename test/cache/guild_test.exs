defmodule Crux.Cache.GuildTest do
  use ExUnit.Case

  @cache Crux.Cache.Guild

  @data %{
    "voice_states" => [],
    "verification_level" => 0,
    "vanity_url_code" => nil,
    "unavailable" => false,
    "system_channel_id" => nil,
    "splash" => nil,
    "roles" => [
      %{
        "position" => 0,
        "permissions" => 104_324_168,
        "name" => "@everyone",
        "mentionable" => false,
        "managed" => false,
        "id" => "260850209699921931",
        "hoist" => false,
        "color" => 0
      },
      %{
        "color" => 8_100_607,
        "hoist" => true,
        "id" => "266010752794492928",
        "managed" => false,
        "mentionable" => true,
        "name" => "bot",
        "permissions" => 0,
        "position" => 2
      }
    ],
    "region" => "amsterdam",
    "presences" => [
      %{
        "user" => %{"id" => "218348062828003328"},
        "status" => "online",
        "game" => nil,
        "client_status" => %{"desktop" => "online"},
        "activities" => []
      },
      %{
        "user" => %{"id" => "242685080693243906"},
        "status" => "online",
        "game" => nil,
        "client_status" => %{"web" => "online"},
        "activities" => []
      }
    ],
    "owner_id" => "218348062828003328",
    "name" => "Amsterdam",
    "mfa_level" => 0,
    "members" => [
      %{
        "user" => %{
          "username" => "space",
          "id" => "218348062828003328",
          "discriminator" => "0001",
          "avatar" => "646a356e237350bf8b8dfde15667dfc4"
        },
        "roles" => [],
        "mute" => false,
        "joined_at" => "2016-12-20T19:25:36.417000+00:00",
        "deaf" => false
      },
      %{
        "user" => %{
          "username" => "spacebot",
          "id" => "242685080693243906",
          "discriminator" => "0234",
          "bot" => true,
          "avatar" => "0482e6a33b5a7a1d747b5aad093706b8"
        },
        "roles" => [],
        "mute" => false,
        "joined_at" => "2018-02-23T13:00:21.329000+00:00",
        "deaf" => false
      },
      %{
        "user" => %{
          "username" => "hariborne",
          "id" => "257884228451041280",
          "discriminator" => "9120",
          "bot" => true,
          "avatar" => "b5c520c7ebecfb8e084b895e00d6bbea"
        },
        "roles" => [],
        "nick" => nil,
        "mute" => false,
        "joined_at" => "2019-03-07T15:39:59.998346+00:00",
        "deaf" => false
      }
    ],
    "member_count" => 3,
    "lazy" => true,
    "large" => false,
    "joined_at" => "2018-02-23T13:00:21.329000+00:00",
    "id" => "260850209699921931",
    "icon" => nil,
    "features" => [],
    "explicit_content_filter" => 0,
    "emojis" => [
      %{
        "roles" => [],
        "require_colons" => true,
        "name" => "cheese",
        "managed" => false,
        "id" => "477490336692961281",
        "animated" => false
      }
    ],
    "description" => nil,
    "default_message_notifications" => 0,
    "channels" => [
      %{
        "type" => 0,
        "topic" => nil,
        "rate_limit_per_user" => 0,
        "position" => 0,
        "permission_overwrites" => [],
        "name" => "general",
        "last_message_id" => "556404156009545738",
        "id" => "260850209699921931"
      },
      %{
        "user_limit" => 0,
        "type" => 2,
        "position" => 0,
        "permission_overwrites" => [],
        "name" => "General",
        "id" => "260850210362753024",
        "bitrate" => 64000
      }
    ],
    "banner" => nil,
    "application_id" => nil,
    "afk_timeout" => 300,
    "afk_channel_id" => nil
  }
  @updated_data %{@data | "name" => "Flensburg"}

  @struct @data |> Crux.Structs.create(Crux.Structs.Guild)
  @updated_struct @updated_data |> Crux.Structs.create(Crux.Structs.Guild)

  @member %{
            "user" => %{
              "username" => "space",
              "id" => "218348062828003328",
              "discriminator" => "0001",
              "avatar" => "646a356e237350bf8b8dfde15667dfc4"
            },
            "roles" => [],
            "mute" => false,
            "joined_at" => "2016-12-20T19:25:36.417000+00:00",
            "deaf" => false,
            "guild_id" => "260850209699921931"
          }
          |> Crux.Structs.create(Crux.Structs.Member)

  @role %{
          "color" => 8_100_607,
          "hoist" => true,
          "id" => "266010752794492928",
          "managed" => false,
          "mentionable" => true,
          "name" => "bot",
          "permissions" => 0,
          "position" => 2,
          "guild_id" => "260850209699921931"
        }
        |> Crux.Structs.create(Crux.Structs.Role)

  doctest @cache

  setup do
    sup = start_supervised!(@cache.Supervisor.Supervisor)

    # Crux.Cache.Guild internally uses those
    start_supervised!(Crux.Cache.Channel)
    start_supervised!(Crux.Cache.Emoji)

    [sup: sup]
  end

  setup do
    guild = @cache.update(@struct)

    [guild: guild]
  end

  ### guild

  test "inserting a guild" do
    # done in setup
    assert @struct == @cache.fetch!(@struct.id)
  end

  test "updating an existing guild" do
    @cache.update(@updated_struct)

    assert @updated_struct == @cache.fetch!(@updated_struct.id)
  end

  test "deleting an existing guild" do
    assert :ok == @cache.delete(@struct.id)

    assert :error == @cache.fetch(@struct.id)
  end

  test "deleting a non existing guild" do
    assert :ok == @cache.delete(0)
  end

  ### end guild
  ### member

  test "inserting a member indirectly" do
    # done in setup
    assert @member == @cache.fetch!(@struct.id).members[@member.user]
  end

  test "inserting a member directly" do
    member = %{@member | user: 130_175_406_673_231_873}

    @cache.update(member)

    assert member == @cache.fetch!(@struct.id).members[member.user]
  end

  test "updating a member" do
    member = %{@member | nick: "a nickname"}

    @cache.update(member)

    assert member == @cache.fetch!(@struct.id).members[member.user]
  end

  test "deleting a member" do
    assert :ok == @cache.delete(@member)

    assert nil == @cache.fetch!(@struct.id).members[@member.user]
  end

  ### end member
  ### role

  test "inserting a role indirectly" do
    # done in setup
    assert @role == @cache.fetch!(@struct.id).roles[@role.id]
  end

  test "inserting a role directly" do
    role = %{@role | id: 242_685_080_693_243_906}

    @cache.update(role)

    assert role == @cache.fetch!(@struct.id).roles[role.id]
  end

  test "updating a role" do
    role = %{@role | name: "new name"}

    @cache.update(role)

    assert role == @cache.fetch!(@struct.id).roles[role.id]
  end

  test "deleting a role" do
    assert :ok == @cache.delete(@role)

    assert nil == @cache.fetch!(@struct.id).members[@role.id]
  end

  ### end role
end
