require "yaml"

class MatrixOrg::AppService::Registration
  struct Namespace
    getter exclusive, regex

    def initialize(@exclusive : Bool, @regex : String)
    end
  end

  def initialize(
    @as_token : String,
    @hs_token : String,
    @id : String,
    @url : String,
    @sender_localpart : String,
    @namespaces : Array(Namespace),
    @rate_limited : Bool | Nil = nil,
    @protocols : Array(String) | Nil = nil,
  )
  end

  def self.generate(
    id : String,
    url : String,
    sender_localpart : String,
    namespaces : Array(Namespace),
    rate_limited : Bool | Nil = nil,
    protocols : Array(String) | Nil = nil,
  )
    new(Random::Secure.hex(32), Random::Secure.hex(32), id, url, sender_localpart, namespaces, rate_limited, protocols)
  end

  def to_yaml
    yaml = {
      id: @id,
      url: @url,
      as_token: @as_token,
      hs_token: @hs_token,
      sender_localpart: @sender_localpart,
    }

    if @namespaces.any?
      yaml = yaml.merge(namespaces: @namespaces.map do |ns|
        { exclusive: ns.exclusive, regex: ns.regex }
      end)
    end

    unless @rate_limited.nil?
      yaml = yaml.merge(rate_limited: @rate_limited)
    end

    if !@protocols.nil? && @protocols.as(Array(String)).any?
      yaml = yaml.merge(protocols: @protocols)
    end

    YAML.dump(yaml)
  end
end
