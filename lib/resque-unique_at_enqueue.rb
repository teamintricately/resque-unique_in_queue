require 'resque/unique_at_enqueue/version'

# Ruby Std Lib
require 'digest/md5'

# External Gems
require 'resque'

# This Gem
require 'resque/plugins/unique_at_enqueue'
require 'resque/unique_at_enqueue/resque_ext/job'
require 'resque/unique_at_enqueue/resque_ext/resque'
require 'resque/unique_at_enqueue/queue'
require 'resque/unique_at_enqueue/configuration'

module Resque
  module UniqueAtEnqueue
    env_debug = ENV['RESQUE_DEBUG']
    ENQUEUE_DEBUG = env_debug == 'true' || (env_debug.is_a?(String) && env_debug.match?(/enqueue/)) || env_debug

    def enqueue_unique_log(message, config_proxy = nil)
      config_proxy ||= uniqueness_configuration
      config_proxy.unique_logger.send(config_proxy.unique_log_level, message) if config_proxy.unique_logger
    end

    def enqueue_unique_debug(message, config_proxy = nil)
      config_proxy ||= uniqueness_configuration
      config_proxy.unique_logger.debug(message) if ENQUEUE_DEBUG
    end
    module_function(:enqueue_unique_log, :enqueue_unique_debug)

    # There are times when the class will need access to the configuration object,
    #   such as to override it per instance method
    def uniq_config
      @uniqueness_configuration
    end

    # For per-class config with a block
    def uniqueness_configure
      @uniqueness_configuration ||= Configuration.new
      yield(@uniqueness_configuration)
    end

    #### CONFIG ####
    class << self
      attr_accessor :uniqueness_configuration
    end
    def uniqueness_config_reset(config = Configuration.new)
      @uniqueness_configuration = config
    end

    def uniqueness_log_level
      @uniqueness_configuration.log_level
    end

    def uniqueness_log_level=(log_level)
      @uniqueness_configuration.log_level = log_level
    end
  end
end
