require "harness/sidekiq/version"

require 'sidekiq'
require 'harness'

module Sidekiq
  module Middleware
    module Server
      class HarnessInstrumentation
        include Harness::Instrumentation

        def call(worker, item, queue)
          time "sidekiq.#{worker.class.name.underscore.gsub('/', '.')}" do
            yield
          end

          increment "sidekiq.job"
        end
      end
    end
  end
end

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add Sidekiq::Middleware::Server::HarnessInstrumentation
  end
end

module Harness
  class SidekiqGauge
    include Instrumentation

    def initialize(namespace = nil)
      @namespace = namespace
    end

    def log
      stats = ::Sidekiq::Stats.new

      gauge namespaced('sidekiq.jobs.processed'), stats.processed
      gauge namespaced('sidekiq.jobs.enqueued'), stats.enqueued
      gauge namespaced('sidekiq.jobs.failed'), stats.failed
      gauge namespaced('sidekiq.jobs.retries'), stats.failed
      gauge namespaced('sidekiq.jobs.scheduled'), stats.scheduled_size
    end

    private
    def namespaced(name)
      [@namespace, name].compact.join '.'
    end
  end
end
