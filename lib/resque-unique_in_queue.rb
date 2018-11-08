# frozen_string_literal: true

require 'resque/unique_in_queue/version'

# Ruby Std Lib
require 'digest/md5'

# External Gems
require 'colorized_string'
require 'resque'

# This Gem
require 'resque/plugins/unique_in_queue'
require 'resque/unique_in_queue/resque_ext/job'
require 'resque/unique_in_queue/resque_ext/resque'
require 'resque/unique_in_queue/queue'
require 'resque/unique_in_queue/configuration'

# See lib/resque/plugins/unique_in_queue.rb for the actual plugin
#
# This is not that ^.  Rather, it is an API used by the plugin or as tools by a
#   developer.  These methods are not intended to be included/extended into
#   Resque, Resque::Job, or Resque::Queue.
module Resque
  module UniqueInQueue
    env_debug = ENV['RESQUE_DEBUG']
    IN_QUEUE_DEBUG = env_debug == 'true' || (env_debug.is_a?(String) && env_debug.match?(/enqueue/)) || env_debug
    PLUGIN_TAG = (ColorizedString['[R-UIQ] '].blue).freeze

    def in_queue_unique_log(message, config_proxy = nil)
      config_proxy ||= uniqueness_configuration
      config_proxy.unique_logger&.send(config_proxy.unique_log_level, message) if config_proxy.unique_logger
    end

    def in_queue_unique_debug(message, config_proxy = nil)
      config_proxy ||= uniqueness_configuration
      config_proxy.unique_logger&.send(config_proxy.unique_log_level, "#{PLUGIN_TAG}#{message}") if IN_QUEUE_DEBUG
    end

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

    self.uniqueness_configuration = Configuration.new # setup defaults

    module_function(:in_queue_unique_log,
                    :in_queue_unique_debug,
                    :uniq_config,
                    :uniqueness_configure,
                    :uniqueness_config_reset,
                    :uniqueness_log_level,
                    :uniqueness_log_level=)
  end
end
