require_relative './measurement_fetcher'
require_relative './result_writer'
require_relative './local_storage'

module Executor
  module DapStorage
    include Executor::LocalStorage
    include MeasurementFetcher
    include ResultWriter
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
      if Dir.exist? @job.options.measurements_path
        @job.args = Dir["#{@job.options.measurements_path}/*"].join(',')
      end
    end

    def stage_out
      puts "Job outpust #{@job.outputs}"
      # comparing.bin -if data/pomiary/UT6.csv,data/pomiary/UT7.csv,data/pomiary/UT8.csv
      # RANK 1: simulation 3:
      # Sensor no 0: 6.77361 (offset: 27) sim. status: -1
      # Sensor no 2: 2.62513 (offset: 882) sim. status: -1
      # RANK 2: simulation 23:
      # Sensor no 0: 7.31727 (offset: 795) sim. status: -1
      # Sensor no 2: 2.50500 (offset: 146) sim. status: -1
      # RANK 3: simulation 1:
      # Sensor no 0: 7.57490 (offset: 136) sim. status: -1
      # Sensor no 2: 2.64121 (offset: 250) sim. status: -1
      # RANK 4: simulation 30:
      # Sensor no 0: 8.55535 (offset: 51) sim. status: -1
      # Sensor no 2: 3.51746 (offset: 135) sim. status: -1

      # how to parse similarity and rank out of above?
      write_result(
          {
              similarity: 0.1,
              rank: 7,
              threat_assessment_id: @job.options.threat_assessment_id,
              scenario_id: @job.options.scenario_id
          }
      )
    end

    def private_token
      ENV['PRIVATE_TOKEN'] || PRIVATE_TOKEN
    end

    def dap_base_url
      ENV['DAP_BASE_URL'] || 'https://dap.moc.ismop.edu.pl'
    end

  end
end