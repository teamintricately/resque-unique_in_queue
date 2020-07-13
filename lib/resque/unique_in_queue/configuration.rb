require 'logger'
module Resque
  module UniqueInQueue
    class Configuration
      DEFAULT_UNIQUE_IN_QUEUE_KEY_BASE = 'r-uiq'.freeze
      DEFAULT_LOG_LEVEL = :debug

      include Singleton

      attr_accessor :debug_mode,
                    :log_level,
                    :logger,
                    :unique_in_queue_key_base

      def initialize
        debug_mode_from_env
        @log_level = DEFAULT_LOG_LEVEL
        @logger = nil
        @unique_in_queue_key_base = DEFAULT_UNIQUE_IN_QUEUE_KEY_BASE
        if @debug_mode
          # Make sure there is a logger when in debug_mode
          @logger ||= Logger.new(STDOUT)
        end
      end

      def to_hash
        {
            debug_mode: debug_mode,
            log_level: log_level,
            logger: logger,
            unique_in_queue_key_base: unique_in_queue_key_base
        }
      end

      def debug_mode=(val)
        @debug_mode = !!val
      end

      private

      def debug_mode_from_env
        env_debug = ENV['RESQUE_DEBUG']
        @debug_mode = !!(env_debug == 'true' || (env_debug.is_a?(String) && env_debug.match?(/queue/)))
      end
    end
  end
end
