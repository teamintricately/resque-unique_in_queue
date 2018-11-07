module Resque
  class Job
    class << self
      # Mark an item as queued
      def create_unique_at_enqueue(queue, klass, *args)
        item = { class: klass.to_s, args: args }
        if Resque.inline? || !Resque::UniqueAtEnqueue::Queue.is_unique?(item)
          return create_without_unique_at_enqueue(queue, klass, *args)
        end
        return "EXISTED" if Resque::UniqueAtEnqueue::Queue.queued?(queue, item)
        create_return_value = false
        # redis transaction block
        Resque.redis.multi do
          create_return_value = create_without_unique_at_enqueue(queue, klass, *args)
          Resque::UniqueAtEnqueue::Queue.mark_queued(queue, item)
        end
        create_return_value
      end

      # Mark an item as unqueued
      def reserve_unique_at_enqueue(queue)
        item = reserve_without_unique_at_enqueue(queue)
        Resque::UniqueAtEnqueue::Queue.mark_unqueued(queue, item) if item && !Resque.inline?
        item
      end

      # Mark destroyed jobs as unqueued
      def destroy_unique_at_enqueue(queue, klass, *args)
        Resque::UniqueAtEnqueue::Queue.destroy(queue, klass, *args) unless Resque.inline?
        destroy_without_unique_at_enqueue(queue, klass, *args)
      end

      alias_method :create_without_unique_at_enqueue, :create
      alias_method :create, :create_unique_at_enqueue
      alias_method :reserve_without_unique_at_enqueue, :reserve
      alias_method :reserve, :reserve_unique_at_enqueue
      alias_method :destroy_without_unique_at_enqueue, :destroy
      alias_method :destroy, :destroy_unique_at_enqueue

      if defined?(Resque::Plugins::PriorityEnqueue::Resque)
        # Hack to support resque-priority_enqueue: https://github.com/coupa/resque-priority_enqueue
        def priority_create_unique_at_enqueue(queue, klass, *args)
          item = { class: klass.to_s, args: args }
          if Resque.inline? || !Resque::UniqueAtEnqueue::Queue.is_unique?(item)
            return priority_create_without_unique_at_enqueue(queue, klass, *args)
          end
          return "EXISTED" if Resque::UniqueAtEnqueue::Queue.queued?(queue, item)
          priority_create_return_value = false
          # redis transaction block
          Resque.redis.multi do
            priority_create_return_value = priority_create_without_unique_at_enqueue(queue, klass, *args)
            Resque::UniqueAtEnqueue::Queue.mark_queued(queue, item)
          end
          priority_create_return_value
        end

        alias_method :priority_create_without_unique_at_enqueue, :priority_create
        alias_method :priority_create, :priority_create_unique_at_enqueue
      end
    end
  end
end
