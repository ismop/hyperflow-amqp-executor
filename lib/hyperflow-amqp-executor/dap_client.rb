require 'faraday'

module DapClient
  def init_connection
    @conn = Faraday.new(url: dap_base_url, ssl:{verify: false})
  end
end