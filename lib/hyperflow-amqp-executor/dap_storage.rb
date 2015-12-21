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
        @job.args = Dir["-if #{@job.options.measurements_path}/*"].join(',')
      end
    end

    def stage_out
      puts "Job outpust #{@job.outputs}"
      # comparing.bin -if data/pomiary/UT6.csv,data/pomiary/UT7.csv,data/pomiary/UT8.csv

      begin
        results = (job_output.split(/^RANK/)) - ['']
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
        write_result(
              {
                  similarity: -1,
                  rank: -1,
                  payload: $!.message,
                  threat_assessment_id: @job.options.threat_assessment_id,
                  scenario_id: @job.options.scenario_id
              }
          )
      end

      # how to parse similarity and rank out of above?






    end

    def job_output
      "RANK 1: simulation 3:\n"\
      "Sensor no 0: 6.77361 (offset: 27) sim. status: -1\n"\
      "Sensor no 2: 2.62513 (offset: 882) sim. status: -1\n"\
      "RANK 2: simulation 23:\n"\
      "Sensor no 0: 7.31727 (offset: 795) sim. status: -1\n"\
      "Sensor no 2: 2.50500 (offset: 146) sim. status: -1\n"\
      "RANK 3: simulation 1:\n"\
      "Sensor no 0: 7.57490 (offset: 136) sim. status: -1\n"\
      "Sensor no 2: 2.64121 (offset: 250) sim. status: -1\n"\
      "RANK 4: simulation 30:\n"\
      "Sensor no 0: 8.55535 (offset: 51) sim. status: -1\n"\
      "Sensor no 2: 3.51746 (offset: 135) sim. status: -1\n"
    end

    def private_token
      ENV['PRIVATE_TOKEN'] || PRIVATE_TOKEN
    end

    def dap_base_url
      ENV['DAP_BASE_URL'] || 'https://dap.moc.ismop.edu.pl'
    end

  end
end