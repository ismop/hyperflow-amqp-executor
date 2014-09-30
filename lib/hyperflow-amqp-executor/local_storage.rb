module Executor
  module LocalStorage
    def workdir
      yield @job.options.workdir if @job.options.respond_to? :workdir else DIR::getwd()
    end
  end
end

