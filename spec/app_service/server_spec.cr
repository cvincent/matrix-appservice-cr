require "../spec_helper"
require "json"

class TestImpl < MatrixOrg::AppService::Server
  property events_handled : Int32
  @events_handled = 0

  private def handle_get_user(context, user_id)
    context.tap do |ctx|
      ctx.response.print("user id: #{user_id}")
    end
  end

  private def handle_get_room(context, room_alias)
    context.tap do |ctx|
      ctx.response.print("room alias: #{room_alias}")
    end
  end

  private def handle_put_event(context, event)
    @events_handled += 1
  end
end

server = TestImpl.new(TEST_HOST, TEST_PORT, TEST_TOKEN, File.new("/dev/null"))
client = HTTP::Client.new(TEST_HOST, TEST_PORT)

describe MatrixOrg::AppService::Server do
  before_all do
    spawn { server.listen! }
    sleep 0.01
  end

  before_each { server.events_handled = 0 }

  after_all { server.stop! }

  it "delegates getting a user" do
    resp = client.get("/_matrix/app/v1/users/fake_user_id?access_token=#{TEST_TOKEN}")
    resp.body.should eq("user id: fake_user_id")
  end

  it "delegates getting a room" do
    resp = client.get("/_matrix/app/v1/rooms/fake_room?access_token=#{TEST_TOKEN}")
    resp.body.should eq("room alias: fake_room")
  end

  it "returns a property error response with an invalid token" do
    resp = client.get("/_matrix/app/v1/rooms/fake_room?access_token=badtoken")
    JSON.parse(resp.body).should eq({
      "errcode" => "M_FORBIDDEN",
      "error" => "Bad token supplied",
    })
  end

  it "handles transactions idempotently" do
    resp = client.put("/_matrix/app/v1/transactions/first_txn?access_token=#{TEST_TOKEN}")
    server.events_handled.should eq(0)
    resp = client.put("/_matrix/app/v1/transactions/second_txn?access_token=#{TEST_TOKEN}", body: "[{}, {}]")
    server.events_handled.should eq(2)
    resp = client.put("/_matrix/app/v1/transactions/third_txn?access_token=#{TEST_TOKEN}", body: "[{}]")
    server.events_handled.should eq(3)
    resp = client.put("/_matrix/app/v1/transactions/second_txn?access_token=#{TEST_TOKEN}", body: "[{}]")
    server.events_handled.should eq(3)
  end
end
