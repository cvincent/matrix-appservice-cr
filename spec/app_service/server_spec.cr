require "../spec_helper"
require "json"

class TestImpl < MatrixOrg::AppService::Server
  property events_handled : Int32
  @events_handled = 0

  private def handle_put_event(event)
    @events_handled += 1
  end

  private def handle_get_user(user_id)
    true
  end

  private def handle_get_room(room_alias)
    true
  end
end

base_server = MatrixOrg::AppService::Server.new(TEST_HOST, TEST_PORT, TEST_TOKEN, File.new("/dev/null"))
test_impl_server = TestImpl.new(TEST_HOST, TEST_PORT, TEST_TOKEN, File.new("/dev/null"))

def spawn_server(server)
  spawn { server.listen! }
  while !server.listening?
    sleep 0.00001
  end
end

def client
  HTTP::Client.new(TEST_HOST, TEST_PORT)
end

def test_authorization_errors
  describe "authorization errors" do
    it "returns unauthorized status when an access_token isn't supplied" do
      resp = client.get("/_matrix/app/v1/users/fake_user_id")
      resp.status.should eq(HTTP::Status::UNAUTHORIZED)
    end

    it "returns forbidden status when an access_token is bad" do
      resp = client.get("/_matrix/app/v1/users/fake_user_id?access_token=BAD#{TEST_TOKEN}")
      resp.status.should eq(HTTP::Status::FORBIDDEN)
    end
  end
end

describe MatrixOrg::AppService::Server do
  describe "the base implementation" do
    around_all do |context|
      spawn_server(base_server)
      context.run
      base_server.stop!
    end

    test_authorization_errors

    it "always responds to PUT transactions with 200 and an empty object" do
      resp = client.put("/_matrix/app/v1/transactions/some_txn?access_token=#{TEST_TOKEN}", body: "[{}, {}]")
      resp.status.should eq(HTTP::Status::OK)
      resp.body.should eq("{}")
    end

    it "always indicates that a user doesn't exist" do
      resp = client.get("/_matrix/app/v1/users/fake_user_id?access_token=#{TEST_TOKEN}")
      resp.status.should eq(HTTP::Status::NOT_FOUND)
    end

    it "always indicates that a room doesn't exist" do
      resp = client.get("/_matrix/app/v1/rooms/fake_room_id?access_token=#{TEST_TOKEN}")
      resp.status.should eq(HTTP::Status::NOT_FOUND)
    end
  end

  describe "a test implementation" do
    around_all do |context|
      spawn_server(test_impl_server)
      context.run
      test_impl_server.stop!
    end

    before_each { test_impl_server.events_handled = 0 }

    test_authorization_errors

    it "handles transactions idempotently (base behavior covers this, but test implementation allows introspecting here)" do
      resp = client.put("/_matrix/app/v1/transactions/first_txn?access_token=#{TEST_TOKEN}")
      test_impl_server.events_handled.should eq(0)
      resp = client.put("/_matrix/app/v1/transactions/second_txn?access_token=#{TEST_TOKEN}", body: "[{}, {}]")
      test_impl_server.events_handled.should eq(2)
      resp = client.put("/_matrix/app/v1/transactions/third_txn?access_token=#{TEST_TOKEN}", body: "[{}]")
      test_impl_server.events_handled.should eq(3)
      resp = client.put("/_matrix/app/v1/transactions/second_txn?access_token=#{TEST_TOKEN}", body: "[{}]")
      test_impl_server.events_handled.should eq(3)
    end

    it "delegates getting a user" do
      resp = client.get("/_matrix/app/v1/users/fake_user_id?access_token=#{TEST_TOKEN}")
      resp.status.should eq(HTTP::Status::OK)
    end

    it "delegates getting a room" do
      resp = client.get("/_matrix/app/v1/rooms/fake_room?access_token=#{TEST_TOKEN}")
      resp.status.should eq(HTTP::Status::OK)
    end
  end
end
