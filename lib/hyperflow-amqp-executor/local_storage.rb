module Executor
  module LocalStorage
    def workdir
      yield @job.options.workdir if @job.options.key?(:workdir) else DIR::getwd()
    end
  end
end

