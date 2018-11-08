require 'logger'
module Resque
  module UniqueInQueue
    class Configuration
      DEFAULT_IN_QUEUE_KEY_BASE = 'r-uiq'.freeze
      DEFAULT_LOCK_AFTER_EXECUTION_PERIOD = 0
      DEFAULT_TTL = -1

      attr_accessor :logger,
                    :log_level,
                    :unique_in_queue_key_base,
                    :lock_after_execution_period,
                    :ttl,
                    :debug_mode
      def initialize(**options)
        @logger = options.key?(:logger) ? options[:logger] : Logger.new(STDOUT)
        @log_level = options.key?(:log_level) ? options[:log_level] : :debug

        # Can't be set per job:
        @unique_in_queue_key_base = options.key?(:unique_in_queue_key_base) ? options[:unique_in_queue_key_base] : DEFAULT_IN_QUEUE_KEY_BASE

        # Can be set per each job:
        @lock_after_execution_period = options.key?(:lock_after_execution_period) ? options[:lock_after_execution_period] : DEFAULT_LOCK_AFTER_EXECUTION_PERIOD
        @ttl = options.key?(:ttl) ? options[:ttl] : DEFAULT_TTL
        env_debug = ENV['RESQUE_DEBUG']
        @debug_mode = options.key?(:debug_mode) ? options[:debug_mode] : env_debug == 'true' || (env_debug.is_a?(String) && env_debug.match?(/in_queue/))
      end

      def unique_logger
        logger
      end

      def unique_log_level
        log_level
      end

      def log(msg)
        Resque::UniqueInQueue.in_queue_unique_log(msg, self)
      end

      def to_hash
        {
          logger: logger,
          log_level: log_level
        }
      end
    end
  end
end