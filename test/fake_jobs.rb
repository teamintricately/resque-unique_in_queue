class FakeJob
  @queue = :normal
end

class FakeUniqueAtEnqueue
  include Resque::Plugins::UniqueAtEnqueue
  @queue = :unique

  def self.perform(_); end
end

class FailingUniqueAtEnqueue
  include Resque::Plugins::UniqueAtEnqueue
  @queue = :unique

  def self.perform(_)
    raise 'Fail'
  end
end

class UniqueAtEnqueueWithTtl
  include Resque::Plugins::UniqueAtEnqueue
  @queue = :unique_with_ttl
  @ttl = 300

  def self.perform(*_); end
end

class UniqueAtEnqueueWithLock
  include Resque::Plugins::UniqueAtEnqueue
  @queue = :unique_with_lock
  @lock_after_execution_period = 150

  def self.perform(*_); end
end
