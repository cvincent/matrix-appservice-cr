require "./src/matrix_org-app_service"

server = MatrixOrg::AppService::Server.new("127.0.0.1", 1234, "testtoken")
server.listen!
server.stop!
