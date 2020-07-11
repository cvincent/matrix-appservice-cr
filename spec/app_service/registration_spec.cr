require "../spec_helper"

describe MatrixOrg::AppService::Registration do
  it "works" do
    reg = MatrixOrg::AppService::Registration.new(
      "1", "2", "3", "4", "5",
      {
        "rooms" => [MatrixOrg::AppService::Registration::Namespace.new(true, "asdf")],
        "users" => [MatrixOrg::AppService::Registration::Namespace.new(true, "asdf")],
      },
      false,
      ["protocol"],
    )

    reg.to_yaml.should be_a(String)
  end

  it "can generate tokens for us" do
    reg = MatrixOrg::AppService::Registration.generate(
      "1", "2", "3",
      {
        "rooms" => [MatrixOrg::AppService::Registration::Namespace.new(true, "asdf")],
        "users" => [MatrixOrg::AppService::Registration::Namespace.new(true, "asdf")],
      },
      false,
      ["protocol"],
    )

    reg.to_yaml.should be_a(String)
  end
end
