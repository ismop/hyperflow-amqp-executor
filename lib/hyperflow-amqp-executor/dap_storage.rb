require_relative './measurement_fetcher'
require_relative './result_writer'
require_relative './local_storage'

module Executor
  module DapStorage
    include Executor::LocalStorage
    include MeasurementFetcher
    include ResultWriter
    def stage_in
      download_scenarios

      get(
         @job.options.context_id,
         nil, # scenario_id = nil because we fetch real data
         @job.options.profile_id,
         @job.options.time_from,
         @job.options.time_to,
         @job.options.filename_prefix,
         @job.options.measurements_path
      )
      if Dir.exist? @job.options.measurements_path
        @job.args = Dir["-if #{@job.options.measurements_path}/*"].join(',')
      end
    end

    def stage_out
      #puts "Job outputs #{@job.outputs}"
      # comparing.bin -if data/pomiary/UT6.csv,data/pomiary/UT7.csv,data/pomiary/UT8.csv

      exit_code = @job.exit_code
      ta_state = nil
      if (exit_code != 0)
        ta_state = :error
      else
        ta_state = :finished
        output = job_output
        if job_output != ''
          begin
            results = (output.split(/^RANK/)) - ['']
            results.each do |result|
              rank = result.match(/^ \d+/)[0].to_i
              similarities = result.split("\n").collect do |s|
                md=s.match(/\d+\.\d+/)
                md ? md[0].to_f : nil
              end.compact
              similarity = similarities.inject {|sum, el| sum += el} / similarities.size
              write_result(
                  {
                      similarity: similarity,
                      rank: rank,
                      payload: 'RANK' + result,
                      threat_assessment_id: @job.options.threat_assessment_id,
                      scenario_id: @job.options.scenario_id
                  }
              )
            end
          rescue
            logger.error $!.message
            ta_state = :error
          end
        end
      end
      update_threat_assessment_state(@job.options.threat_assessment_id, ta_state)
    end

    def job_output
      @job.std_out || ''
      # "RANK 1: simulation 3:\n"\
      # "Sensor no 0: 6.77361 (offset: 27) sim. status: -1\n"\
      # "Sensor no 2: 2.62513 (offset: 882) sim. status: -1\n"\
      # "RANK 2: simulation 23:\n"\
      # "Sensor no 0: 7.31727 (offset: 795) sim. status: -1\n"\
      # "Sensor no 2: 2.50500 (offset: 146) sim. status: -1\n"\
      # "RANK 3: simulation 1:\n"\
      # "Sensor no 0: 7.57490 (offset: 136) sim. status: -1\n"\
      # "Sensor no 2: 2.64121 (offset: 250) sim. status: -1\n"\
      # "RANK 4: simulation 30:\n"\
      # "Sensor no 0: 8.55535 (offset: 51) sim. status: -1\n"\
      # "Sensor no 2: 3.51746 (offset: 135) sim. status: -1\n"
    end

    def private_token
      ENV['PRIVATE_TOKEN'] || PRIVATE_TOKEN
    end

    def dap_base_url
      ENV['DAP_BASE_URL'] || 'https://dap.moc.ismop.edu.pl'
    end

    private

    def download_scenarios
      scenario_ids = @job.options.scenario_ids || []
      scenario_ids.each do |scenario_id|
        get(
           @job.options.context_id,
           scenario_id,
           @job.options.profile_id,
           @job.options.time_from,
           @job.options.time_to,
           @job.options.filename_prefix,
           @job.options.measurements_path
        )
      end
    end

  end
end