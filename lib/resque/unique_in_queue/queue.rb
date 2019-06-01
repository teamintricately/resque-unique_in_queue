module Resque
  module UniqueInQueue
    module Queue
      def queued?(queue, item)
        return false unless is_unique?(item)

        redis.get(unique_key(queue, item)) == '1'
      end

      def mark_queued(queue, item)
        return unless is_unique?(item)

        key = unique_key(queue, item)
        redis.set(key, 1)
        ttl = item_ttl(item)
        redis.expire(key, ttl) if ttl >= 0
      end

      def mark_unqueued(queue, job)
        item = job.is_a?(Resque::Job) ? job.payload : job
        return unless is_unique?(item)

        ttl = lock_after_execution_period(item)
        if ttl == 0
          redis.del(unique_key(queue, item))
        else
          redis.expire(unique_key(queue, item), ttl)
        end
      end

      def unique_key(queue, item)
        const_for(item).unique_in_queue_redis_key(queue, item)
      end

      def is_unique?(item)
        const_for(item).included_modules.include?(::Resque::Plugins::UniqueInQueue)
      rescue NameError
        false
      end

      def item_ttl(item)
        const_for(item).ttl
      rescue NameError
        -1
      end

      def lock_after_execution_period(item)
        const_for(item).lock_after_execution_period
      rescue NameError
        0
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
        pattern = "#{Resque::UniqueInQueue.configuration&.unique_in_queue_key_base}:queue:#{queue}:job:*"
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

      module_function :queued?, :mark_queued, :mark_unqueued, :unique_key
      module_function :is_unique?, :item_ttl, :lock_after_execution_period
      module_function :destroy, :cleanup, :redis, :item_class, :const_for
    end
  end
end
