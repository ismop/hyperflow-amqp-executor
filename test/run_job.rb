require 'test/unit'
require_relative '../lib/hyperflow-amqp-executor'


class RunJob < Test::Unit::TestCase

  def test_job_run
    # add data about job, storage setting is overriden by local config
    payload = '{ "executable" : "ruby /home/servers/mr_scenario_selection/mr_worker.rb", "args" : "0004 1 FIXME-dapToken FIXME-dapLocation \"2014-06-26 06:00:12\" \"2014-06-27 11:03:47\", "inputs": ["0": "some_input"], "outputs": ["0": "some_output"], "options":{"storage":"local"}}'
    job_data = RecursiveOpenStruct.new(JSON.parse(payload), recurse_over_arrays: true)
    job = Executor::Job.new('doesntmatterfornow', job_data)
    puts job.run
  end
end