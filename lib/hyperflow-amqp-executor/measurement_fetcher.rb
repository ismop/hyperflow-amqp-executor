require 'fileutils'
require 'json'
require 'date'
require_relative './dap_client'

module MeasurementFetcher
  include DapClient

  def get(ctx_id, scenario_id, profile_id, from, to, file_name_prefix = '', working_dir = '/tmp/')
    scenario = !scenario_id.nil?
    if scenario
      working_dir = Dir.home + '/data/symulacje/'
      file_name_prefix = "scen_#{scenario_id}_"
    end
    init_connection unless @conn
    devices = devices_for_profile(profile_id)
    devices.each do |dev|
      next if scenario && scenario_downloaded?(working_dir, file_name_prefix, dev['custom_id'])


      parameter_ids = dev['parameter_ids']
      next if parameter_ids.size == 0
      parameters = parameters(parameter_ids)

      temp_param = select_param_of_type(parameters, 'Temperatura')
      next unless temp_param
      temp_param_id = temp_param['id']

      press_param = select_param_of_type(
          parameters,
          'Ciśnienie porowe'
      )
      next unless press_param
      press_param_id = press_param['id']

      temp_tl = timeline(ctx_id, scenario_id, temp_param_id)
      next unless temp_tl
      temp_tl_id = temp_tl['id']

      press_tl = timeline(ctx_id, scenario_id, press_param_id)
      next unless press_tl
      press_tl_id = press_tl['id']

      temp_measurements = if scenario
                            temperature_measurements(temp_tl_id)
                          else
                              temperature_measurements(temp_tl_id, from, to)
                          end
      next unless temp_measurements

      press_measurements = if scenario
                             pressure_measurements(press_tl_id)
                           else
                             pressure_measurements(press_tl_id, from, to)
                           end
      next unless press_measurements

      next if (temp_measurements.size == 0 || press_measurements.size == 0)
      next if temp_measurements.size != press_measurements.size

      working_dir << '/' unless working_dir.end_with? '/'

      write_measurements(
          dev, press_measurements, temp_measurements,
          file_name_prefix, working_dir, scenario
      )
    end
  end

  def scenario_downloaded?(working_dir, fname_prefix, custom_id)
    file_name = "#{working_dir}#{fname_prefix}#{custom_id}.csv"
    File.exist? file_name
  end

  private

  def write_measurements(dev, p_measurements, t_measurements, fname_prefix, working_dir, scenario)
    unless Dir.exist?(working_dir)
      FileUtils.mkpath(working_dir)
    end
    file_name = "#{working_dir}#{fname_prefix}#{dev['custom_id']}.csv"
    puts "Writing file #{file_name}"
    File.open(file_name, 'w') do |file|
      t_measurements.each_index do |i|
        # data in scenario and measurement files have columns in different order
        row = "0,0,0,"\
            "#{"0," unless scenario}"\
            "#{t_measurements[i]['value']},"\
            "#{p_measurements[i]['value']},"\
            "#{timestamp(t_measurements[i]['timestamp'])},"\
             "#{"0," if scenario}"\
            "#{dev['custom_id']}\n"
        file.write(row)
      end
    end
  end

  def timestamp(date_str)
    DateTime.parse(date_str).to_time.to_i
  end

  def devices_for_profile(profile_id)
    devices_str = read_from_cache("device_cache_for_profile_#{profile_id}") ||
        devices_for_profile_from_dap(profile_id)
    JSON.parse(devices_str)['devices']
  end

  def read_from_cache(file_name)
    cache_file_name = "/tmp/#{file_name}"
    File.exist?(cache_file_name) ? IO.read(cache_file_name) : nil
  end

  def devices_for_profile_from_dap(profile_id)
    devices_resp = @conn.get(
        "/api/v1/devices?profile_id=#{profile_id}",
        { private_token: private_token }
    ).body
    write_cache("device_cache_for_profile_#{profile_id}", devices_resp)
    devices_resp
  end

  def select_param_of_type(parameters, param_type)
    parameters.select do |p|
      p['measurement_type_name'] == param_type
    end.first
  end

  def write_cache(file_name, content)
    cache_file_name = "/tmp/#{file_name}"
    IO.write(cache_file_name, content)
  end

  def parameters(parameter_ids)
    parameters_resp =
      read_from_cache("parameter_cache_for_ids_#{parameter_ids}") ||
      parameters_from_dap(parameter_ids)
    JSON.parse(parameters_resp)['parameters']
  end

  def parameters_from_dap(parameter_ids)
    parameters_resp = @conn.get(
      "/api/v1/parameters?id=#{parameter_ids.join(',')}",
      {private_token: private_token}
    ).body
    write_cache "parameter_cache_for_ids_#{parameter_ids}", parameters_resp
    parameters_resp
  end

  def timeline(ctx_id, scenario_id, parameter_id)
    timeline_resp =
      read_from_cache("timeline_cache_for_ctx_#{ctx_id}_for_scenario_#{scenario_id}_for_parameter_#{parameter_id}") ||
      timeline_from_dap(ctx_id, scenario_id, parameter_id)
    JSON.parse(timeline_resp)['timelines'].first
  end

  def timeline_from_dap(ctx_id, scenario_id, parameter_id)
    timeline_resp = @conn.get(
        "/api/v1/timelines?parameter_id=#{parameter_id}"\
        "&context_id=#{ctx_id}"\
        "#{"&scenario_id=#{scenario_id}" if scenario_id}",
        {private_token: private_token}
    ).body
    write_cache("timeline_cache_for_ctx_#{ctx_id}_for_scenario_#{scenario_id}_for_parameter_#{parameter_id}", timeline_resp)
    timeline_resp
  end

  def temperature_measurements(timeline_id, from = nil, to = nil)
    temp_measurements_resp = @conn.get(
        "/api/v1/measurements?timeline_id=#{timeline_id}"\
        "#{"&time_from=#{from}" if from}"\
        "#{"&time_to=#{to}" if to}",
        {private_token: private_token}
    ).body
    JSON.parse(temp_measurements_resp)['measurements']
  end

  def pressure_measurements(timeline_id, from = nil, to = nil)
    press_measurements_resp = @conn.get(
        "/api/v1/measurements?timeline_id=#{timeline_id}"\
        "#{"&time_from=#{from}" if from}"\
        "#{"&time_to=#{to}" if to}",
        {private_token: private_token}
    ).body
    JSON.parse(press_measurements_resp)['measurements']
  end

end
