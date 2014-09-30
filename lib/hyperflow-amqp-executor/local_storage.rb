module Executor
  module LocalStorage
    def workdir
      yield @job.options.respond_to?("workdir") ? @job.options.workdir : Dir::getwd()
    end
  end
end

