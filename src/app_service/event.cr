# TODO: Go through the spec and make a test that each given example from the spec parses

require "json"
require "./json_discriminator_with_fallback"

abstract struct MatrixOrg::AppService::Event
  include JSON::Serializable
  include JsonDiscriminatorWithFallback

  use_json_discriminator_with_fallback "type", Unknown, {
    "m.room.message": RoomEvent,
    "m.room.canonical_alias": RoomEvent,
  }

  property type : String
  property event_id : String
  property origin_server_ts : Int64
  property room_id : String
  property sender : String
  property unsigned : UnsignedData?

  class UnsignedData # Needs to be a class because it has a circular reference back to Event
    include JSON::Serializable
    property age : Int32
    property redacted_because : Event?
    property transaction_id : String?
  end

  abstract struct RoomEvent < Event
    include JsonDiscriminatorWithFallback

    use_json_discriminator_with_fallback "type", Unknown, {
      "m.room.canonical_alias": CanonicalAlias,
      "m.room.message": Message,
    }

    struct CanonicalAlias < RoomEvent
      property content : Content
      struct Content
        include JSON::Serializable
        property alias : String
        property alt_aliases : Array(String)
      end
    end

    struct CanonicalAlias < RoomEvent
      property content : Content
      struct Content
        include JSON::Serializable
        property alias : String
        property alt_aliases : Array(String)
      end
    end

    struct Create < RoomEvent
      property creator : String
      property federate : Bool
      property room_version : Int32
      property predecessor : Predecessor

      struct Predecessor
        include JSON::Serializable
        property event_id : String
        property room_id : String
      end
    end

    struct JoinRules < RoomEvent
      property content : Content
      struct Content
        include JSON::Serializable
        property join_rule : String
      end
    end

    struct Member < RoomEvent
      # NOTE: Read the spec, come back to this
      property state_key : String
      property content : Content
      struct Content
        include JSON::Serializable
      end
    end

    struct PowerLevels < RoomEvent
      property content : Content
      struct Content
        include JSON::Serializable
        property ban : Int8
        property events_default : Int8
        property invite : Int8
        property kick : Int8
        property redact : Int8
        property state_default : Int8
        property users_default : Int8
        property events : Hash(String, Int8)
        property users : Hash(String, Int8)
        property notifications : Hash(String, Int8)
      end
    end

    struct Redaction < RoomEvent
      property redacts : String
      property content : Content
      struct Content
        include JSON::Serializable
        property reason : String
      end
    end

    struct Message < RoomEvent
      property content : Content

      abstract struct Content
        include JSON::Serializable
        include JsonDiscriminatorWithFallback

        use_json_discriminator_with_fallback "msgtype", Unknown, {
          "m.audio": Audio,
          "m.emote": Emote,
        }

        property msgtype : String
        property body : String

        struct Unknown < Content
        end

        struct Audio < Content
          property url : String
          property info : Info

          struct Info
            include JSON::Serializable
            property duration : Int32
            property mimetype : String
            property size : Int32
          end
        end

        struct Emote < Content
          property body : String
          property format : String
          property formatted_body : String
        end

        struct File < Content
          property body : String
          property filename : String
          property url : String
          property info : Info

          struct Info
            include JSON::Serializable
            property mimetype : String
            property size : Int32
          end
        end

        struct Image < Content
          url : String
          info : Info

          struct Info
            include JSON::Serializable
            property w : Int32
            property h : Int32
            property mimetype : String
            property size : Int32
          end
        end

        struct Location < Content
          property geo_uri : String
          property info : Info

          struct Info
            include JSON::Serializable
            property thumbnail_url : String
            property thumbnail_info : MatrixOrg::AppService::Event::RoomEvent::Message::Content::Image::Info
          end
        end

        struct Notice < Content
          property format : String
          property formatted_body : String
        end

        abstract struct ServerNotice < Content
          use_json_discriminator_with_fallback "server_notice_type", Unknown, {
            "m.server_notice.usage_limit_reached": UsageLimitReached,
          }

          property server_notice_type : String

          struct Unknown < ServerNotice
          end

          struct UsageLimitReached < ServerNotice
            property admin_contact : String
            property limit_type : String
          end
        end

        struct Text < Content
          property format : String
          property formatted_body : String
        end

        struct Video < Content
          property url : String
          property info : Info

          struct Info
            include JSON::Serializable
            property w : Int32
            property h : Int32
            property duration : Int32
            property mimetype : String
            property size : Int32
            property thumbnail_url : String
            property thumbnail_info : MatrixOrg::AppService::Event::RoomEvent::Message::Content::Image::Info
          end
        end
      end

    end
  end

  struct Unknown < Event
  end
end
