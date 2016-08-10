require 'benchmark'

require_relative '../lib/hyperflow-amqp-executor/dap_storage'
require_relative './config.rb'

class Fetcher
  include Executor::DapStorage
end

context_id = 1
scenario_id = nil
profile_id = 8
time_from = '2015-10-04 7:00:00 +0200'
time_to = '2015-10-04 8:00:00 +0200'

f = Fetcher.new
time = Benchmark.realtime do
  f.get(context_id,scenario_id,profile_id, time_from,time_to)
end

puts "Time: #{time}"