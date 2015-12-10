require_relative './measurement_fetcher'
require_relative './local_storage'

module Executor
  module DapStorage
    include Executor::LocalStorage
    include MeasurementFetcher
    def stage_in
      get(
         @job.options.context_id,
         @job.options.scenario_id,
         @job.options.profile_id,
         @job.options.time_from,
         @job.options.time_to,
         @job.options.filename_prefix,
         @job.options.measurements_path
      )
    end

    def stage_out

    end

    def private_token
      ENV['PRIVATE_TOKEN'] || PRIVATE_TOKEN
    end

    def dap_base_url
      ENV['DAP_BASE_URL'] || 'https://dap.moc.ismop.edu.pl'
    end

  end
end