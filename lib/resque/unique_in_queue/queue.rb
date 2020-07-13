module Resque
  module UniqueInQueue
    module Queue
      def queued?(queue, item)
        return false unless is_unique?(item)

        key   = unique_key(queue, item)
        value = unique_value(queue, item)

        redis.sismember(key, value)
      end

      def mark_queued(queue, item)
        return unless is_unique?(item)

        key   = unique_key(queue, item)
        value = unique_value(queue, item)

        redis.sadd(key, value)
      end

      def mark_unqueued(queue, job)
        item = job.is_a?(Resque::Job) ? job.payload : job
        return unless is_unique?(item)

        key   = unique_key(queue, item)
        value = unique_value(queue, item)

        redis.srem(key, value)
      end

      def unique_key(queue, item)
        const_for(item).unique_in_queue_redis_key(queue, item)
      end

      def unique_value(queue, item)
        const_for(item).unique_in_queue_redis_value(queue, item)
      end

      def is_unique?(item)
        const_for(item).included_modules.include?(::Resque::Plugins::UniqueInQueue)
      rescue NameError
        false
      end

      def destroy(queue, klass, *args)
        klass = klass.to_s
        redis_queue = "queue:#{queue}"

        redis.lrange(redis_queue, 0, -1).each do |string|
          json = Resque.decode(string)
          next unless json['class'] == klass
          next if args.any? && json['args'] != args

          Resque::UniqueInQueue::Queue.mark_unqueued(queue, json)
        end
      end

      def cleanup(queue)
        pattern = "#{Resque::UniqueInQueue.configuration&.unique_in_queue_key_base}:queue:#{queue}:job"
        keys = redis.scan_each(match: pattern, count: 1_000_000).to_a
        redis.del(keys) if keys.any?
      end

      private

      def redis
        Resque.redis
      end

      def item_class(item)
        item[:class] || item['class']
      end

      def const_for(item)
        Resque.constantize(item_class(item))
        end

      module_function :queued?, :mark_queued, :mark_unqueued, :unique_key, :unique_value,
                      :is_unique?, :destroy, :cleanup, :redis, :item_class, :const_for
    end
  end
end
