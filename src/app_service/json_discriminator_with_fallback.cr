module JsonDiscriminatorWithFallback
  macro use_json_discriminator_with_fallback(field, fallback, mapping)
    {% unless mapping.is_a?(HashLiteral) || mapping.is_a?(NamedTupleLiteral) %}
      {% mapping.raise "mapping argument must be a HashLiteral or a NamedTupleLiteral, not #{mapping.class_name.id}" %}
    {% end %}

    def self.new(pull : ::JSON::PullParser)
      location = pull.location

      discriminator_value = nil

      # Try to find the discriminator while also getting the raw
      # string value of the parsed JSON, so then we can pass it
      # to the final type.
      json = String.build do |io|
        JSON.build(io) do |builder|
          builder.start_object
          pull.read_object do |key|
            if key == {{field.id.stringify}}
              discriminator_value = pull.read_string
              builder.field(key, discriminator_value)
            else
              builder.field(key) { pull.read_raw(builder) }
            end
          end
          builder.end_object
        end
      end

      unless discriminator_value
        raise ::JSON::MappingError.new("Missing JSON discriminator field '{{field.id}}'", to_s, nil, *location, nil)
      end

      case discriminator_value
        {% for key, value in mapping %}
        when {{key.id.stringify}}
          {{value.id}}.from_json(json)
        {% end %}
      else
        {{fallback.id}}.from_json(json)
      end
    end
  end
end
