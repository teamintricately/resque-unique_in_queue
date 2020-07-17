# frozen_string_literal: true

module Resque
  module Plugins
    # If you want your job to support uniqueness at enqueue-time, simply include
    #   this module into your job class.
    #
    #   class EnqueueAlone
    #     @queue = :enqueue_alone
    #     include Resque::Plugins::UniqueInQueue
    #
    #     def self.perform(arg1, arg2)
    #       alone_stuff
    #     end
    #   end
    #
    module UniqueInQueue
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def unique_in_queue_redis_key(queue, item)
          "#{unique_in_queue_key_base}:queue:#{queue}:job"
        end

        def unique_in_queue_redis_value(queue, item)
          Resque::UniqueInQueue::Queue.const_for(item).redis_key(item)
        end

        # Payload is what Resque stored for this job along with the job's class name:
        # a hash containing string keys 'class' and 'args'
        def redis_key(payload)
          payload = Resque.decode(Resque.encode(payload))
          job  = payload['class']
          args = payload['args']
          args.map! do |arg|
            arg.is_a?(Hash) ? arg.sort : arg
          end

          Digest::MD5.hexdigest Resque.encode(class: job, args: args)
        end

        # Should not generally be overridden per each class because it wouldn't
        #   make sense.
        # It wouldn't be able to determine or enforce uniqueness across queues,
        #   and general cleanup of stray keys would be nearly impossible.
        def unique_in_queue_key_base
          instance_variable_get(:@unique_in_queue_key_base) ||
              instance_variable_set(:@unique_in_queue_key_base, Resque::UniqueInQueue.configuration&.unique_in_queue_key_base)
        end
      end
    end
  end
end
