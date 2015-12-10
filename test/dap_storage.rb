require 'test/unit'
require_relative '../lib/hyperflow-amqp-executor/dap_storage'

class DapStorage < Test::Unit::TestCase
  include Executor::DapStorage

  def test_stage_in
    executor = DapStorageTester.new

    # context 1 Obwałowanie eksperymentalne - sensory Budokop
    # context 2 Scenariusze

    puts '----- Getting scenarios data -----'
    context_id = 2
    scenario_id = 26 # for now we have 25 scenarios, check their ids in DAP

    # nil from and to means all available data
    time_from = nil # nil # scenario starts at '1970-01-01 0:00:00 +0200'
    time_to = nil # '1970-01-01 8:00:00 +0200'

    # time_from = '1970-01-01 0:00:00 +0200'
    # time_to = '1970-01-01 8:00:00 +0200'

    # scenarios are not available for all profiles
    # there is some data available for profile with id = 2
    [1, 2, 3, 4, 5, 6, 7, 8, 9, 10].each do |profile_id|
       puts "---Getting scenario data for profile with id #{profile_id}---"
       executor.get(context_id, scenario_id, profile_id, time_from, time_to,
                   "scenario_#{scenario_id}_", '/tmp/scenarios')
       puts '============================================================'
     end

    puts '----- Got available scenarios data -----'

    puts '----- Getting measurements data -----'
    context_id = 1
    scenario_id = nil

    time_from = '2015-10-01 0:00:00 +0200'
    time_to = '2015-10-01 8:00:00 +0200'

    [1, 2, 3, 4, 5, 6, 7, 8, 9, 10].each do |profile_id|
      puts "---Getting measurements for profile with id #{profile_id}---"
      executor.get(context_id, scenario_id, profile_id, time_from, time_to,
                  nil, '/tmp/measurements')
      puts '============================================================'
    end

    puts '----- Got available measurements data -----'

    puts '===== FINISHED ====='
  end

  def test_stage_out

  end

  class DapStorageTester
    include Executor::DapStorage

    DAP_BASE_URL = 'https://dap.moc.ismop.edu.pl'
    def private_token
      ENV['PRIVATE_TOKEN']
    end

    def dap_base_url
      ENV['DAP_BASE_URL'] || DAP_BASE_URL
    end
  end

end