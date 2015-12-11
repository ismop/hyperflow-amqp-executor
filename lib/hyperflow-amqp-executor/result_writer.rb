require 'json'
require_relative './dap_client'

module ResultWriter
  include DapClient

  def write_result(result = {})
    init_connection unless @conn
    @conn.post do |req|
      req.url '/api/v1/results'
      req.headers['PRIVATE-TOKEN'] = private_token
      req.headers['Content-Type'] = 'application/json'
      req.body = result.to_json
    end
  end
end