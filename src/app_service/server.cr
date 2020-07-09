require "router"
require "json"

class MatrixOrg::AppService::Server
  include Router

  @txn_ids = [] of String

  private class MissingAccessToken < Exception
  end

  private class InvalidAccessToken < Exception
  end

  def initialize(@host : String, @port : Int32, @hs_token : String, @logger : IO = STDOUT, @txn_buffer_size : Int32 = 128)
    draw_routes!
    @server = HTTP::Server.new(route_handler)
  end

  def listen!
    @server.bind_tcp(@host, @port)
    @logger.puts("Listening on #{@host}:#{@port}...")
    @server.listen
  end

  def listening?
    @server.listening?
  end

  def stop!
    @server.close
  end

  private def draw_routes!
    put "/_matrix/app/v1/transactions/:txn_id" do |context, params|
      handle_request(context, params) do
        put_transaction(context, params["txn_id"])
      end
    end

    get "/_matrix/app/v1/users/:user_id" do |context, params|
      handle_request(context, params) do
        if !handle_get_user(params["user_id"])
          context.response.status = HTTP::Status::NOT_FOUND
        end
      end
    end

    get "/_matrix/app/v1/rooms/:alias" do |context, params|
      handle_request(context, params) do
        if !handle_get_room(params["alias"])
          context.response.status = HTTP::Status::NOT_FOUND
        end
      end
    end
  end

  private def handle_request(context, params, &block)
    query_params = (context.request.query || "").split("&").map(&.split("=")).to_h rescue {} of String => String
    params = params.merge(query_params)

    begin
      log_request(context, params)
      validate_request!(context, params)
      yield
    rescue MissingAccessToken
      context.response.status = HTTP::Status::UNAUTHORIZED
    rescue InvalidAccessToken
      context.response.status = HTTP::Status::FORBIDDEN
    end

    context
  end

  private def log_request(context, params)
    @logger.puts("#{context.request.method} #{context.request.path}")
    @logger.puts(params.inspect)
    @logger.puts("")
  end

  private def validate_request!(context, params)
    if !params.has_key?("access_token")
      raise MissingAccessToken.new
    elsif params["access_token"] != @hs_token
      raise InvalidAccessToken.new
    end
  end

  private def put_transaction(context, txn_id)
    body = extract_body(context.request.body)
    body = "[]" if body.blank?

    if !@txn_ids.includes?(txn_id)
      JSON.parse(body).as_a.each do |event|
        handle_put_event(event)
      end

      @txn_ids.unshift(txn_id)
      @txn_ids = @txn_ids[0, @txn_buffer_size - 1]
    end

    context.response.print("{}")
    context
  end

  private def handle_put_event(event)
  end

  private def handle_get_user(user_id)
    false
  end

  private def handle_get_room(room_alias)
    false
  end

  private def extract_body(body : Nil)
    ""
  end

  private def extract_body(body : IO)
    body.gets_to_end
  end
end
