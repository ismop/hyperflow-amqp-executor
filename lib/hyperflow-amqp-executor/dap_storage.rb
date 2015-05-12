require 'csv'
require 'faraday'
require 'json'

module Executor
  module DAPStorage
    #TODO: Download scenario and save to workdir
    def stage_in
      @job.inputs.each do |file|
        connection = Faraday.new(url: dap_location, ssl: {verify: false}) do |faraday|
          faraday.request :url_encoded
      #    faraday.response :logger
          faraday.adapter Faraday.default_adapter
          faraday.headers['PRIVATE-TOKEN'] = dap_token
          faraday.headers['Content-Type'] = 'application/json'
        end

        response = connection.get do |req|
          req.url 'api/v1/sections/'
          req.params['id'] = section_id
        end

        sensor_ids = JSON.parse(response.body)['sections'][0]['sensor_ids'].sort

        response = connection.get do |req|
          req.url "/api/v1/measurements/"
          req.params['time_from'] = date_from
          req.params['time_to'] = date_to
          req.params['sensor_id'] = sensor_ids
          # req.options.timeout = 10
        end

        meas = JSON.parse(response.body)['measurements']

        input = {}
        sensor_ids.each do |sensor_id|
          input[sensor_id] = (meas.select { |m| m['sensor_id'] == sensor_id }).sort { |x, y| x['timestamp'] <=> y['timestamp'] }
        end

        File.open(input_file_location, "w") do |input_file|
          input_file.write(sensor_ids.join(", ") + "\n")
          begin
            (input[sensor_ids[0]].length).times do |i|
              line_vals = sensor_ids.collect { |id| input[id][i]['value'] }
              input_file.write(line_vals.join(", ") + "\n")
            end
          end
        end
        # Executor::logger.debug "[#{@id}] Copying #{file.name} to tmpdir"
        # FileUtils.copy(@job.options.workdir + file.name, @workdir + "/" + file.name)
      end
    end

    #TODO: upload results
    def stage_out
      @job.outputs.each do |file|
        ranks = []
        output_file = File.open(output_file_location, "r") do |file|
          lines = file.readlines.first(10)
          ranks = lines
        end

        output = []

        ranks.each do |rank|
          rank_s = rank.split
          result = {
              :similarity => rank_s[1],
              :section_id => section_id.to_i,
              :threat_assessment_id => experiment_id.to_i,
              :scenario_id => rank_s[0].to_i + 1
          }

          response = connection.post do |req|
            req.url "/api/v1/results"
            req.body = {:result => result}.to_json
          end

          raise "Error while uploading results. Error code #{response.status}" unless response.status == 200

          output.push({
                          'similarity' => result[:similarity],
                          'section_id' => result[:section_id],
                          'threat_assessment_id' => result[:threat_assessment_id],
                          'scenario_id' => result[:scenario_id]
                      })
        end
        # Executor::logger.debug "[#{@id}] Copying #{file.name} from tmpdir"
        # FileUtils.copy(@workdir + "/" + file.name, @job.options.workdir + file.name)
      end
    end

    def workdir
      yield @job.options.respond_to?("workdir") ? @job.options.workdir : Dir::getwd()
    end
  end
end

