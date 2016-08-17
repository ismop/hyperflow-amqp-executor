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

  def update_threat_assessment_state(threat_assessment_id, state)
    init_connection unless @conn
    @conn.put do |req|
      req.url "/api/v1/threat_assessments/#{threat_assessment_id}"
      req.headers['PRIVATE-TOKEN'] = private_token
      req.headers['Content-Type'] = 'application/json'
      req.body = {status: state}.to_json
    end
  end
end
