require 'test/unit'
require_relative '../lib/hyperflow-amqp-executor'


class RunJob < Test::Unit::TestCase

  def test_job_run
    # add data about job, storage setting is overriden by local config
    ensure_private_token
    job_conf = {
        executable: 'echo "ISMOP"',
        args: '', # cmd line arg for comparator
        options: {
            storage: 'dap', context_id: 1, scenario_id: nil,
            time_from: '2015-10-01 0:00:00 +0200',
            time_to: '2015-10-01 8:00:00 +0200',
            profile_id: 8,
            filename_prefix: nil,
            measurements_path: '/tmp/measurements'
        }
    }

    job_data = RecursiveOpenStruct.new(job_conf, recurse_over_arrays: true)
    job = Executor::Job.new('doesntmatterfornow', job_data)
    #puts job_data.executable
    puts job.run
  end

  private
  def ensure_private_token
    unless ENV['PRIVATE_TOKEN']
      if File.exist? 'config.rb'
        require_relative './config.rb'
      end
      unless Executor::DapStorage.const_defined? 'PRIVATE_TOKEN'
        fail 'DAP private token is not defined. Create a test/config.rb file '\
             'with Executor::DapStorage::PRIVATE_TOKEN = \'TOKEN\''\
             ' or set PRIVATE_TOKEN env variable.'
      end
    end
  end
end