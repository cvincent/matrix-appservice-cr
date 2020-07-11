require "option_parser"
require "./src/app_service/registration"

id : String | Nil = nil
url : String | Nil = nil
namespace : String | Nil = nil

parser = OptionParser.parse do |parser|
  parser.banner = "Usage: salute [arguments]"
  parser.on("-i ID", "--id=ID", "REQUIRED: ID for this app service") { |iid| id = iid }
  parser.on("-u APP_SERVICE_URL", "--app-service-url=APP_SERVICE_URL", "REQUIRED: URL where the homeserver can access the app service") { |iurl| url = iurl }
  parser.on("-n NAMESPACE", "--namespace=NAMESPACE", "Namespace for the app service bot, users, and rooms") { |ins| namespace = ins }
  parser.on("-h", "--help", "Show this help") do
    puts parser
    exit
  end

  parser.invalid_option do |flag|
    STDERR.puts "ERROR: #{flag} is not a valid option."
    STDERR.puts parser
    exit(1)
  end
end

def assert_string(parser, argname, arg)
  if arg.nil?
    puts "Missing required argument -#{argname}.\n\n"
    puts parser
    exit(1)
  end
end

assert_string(parser, "i", id)
assert_string(parser, "u", url)

namespace ||= "_#{id}_"

puts MatrixOrg::AppService::Registration.generate(
  id.as(String),
  url.as(String),
  "#{namespace}bot",
  {
    "users" => [MatrixOrg::AppService::Registration::Namespace.new(true, "@#{namespace}.*")],
    "aliases" => [MatrixOrg::AppService::Registration::Namespace.new(true, "##{namespace}.*")],
    "rooms" => [] of MatrixOrg::AppService::Registration::Namespace,
  }
).to_yaml
