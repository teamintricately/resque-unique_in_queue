require 'test_helper'

class JobTest < Test::Unit::TestCase
  setup do
    Resque.redis.flushall
  end

  should "enqueue identical jobs once" do
    Resque.enqueue FakeUniqueJob, "x"
    Resque.enqueue FakeUniqueJob, "x"
    assert_equal 1, Resque.size(:unique)
  end

  should "allow the same jobs to be executed one after the other" do
    Resque.enqueue FakeUniqueJob, "foo"
    Resque.enqueue FakeUniqueJob, "foo"
    assert_equal 1, Resque.size(:unique)
    Resque.reserve(:unique)
    assert_equal 0, Resque.size(:unique)
    Resque.enqueue FakeUniqueJob, "foo"
    Resque.enqueue FakeUniqueJob, "foo"
    assert_equal 1, Resque.size(:unique)
  end

  should "consider equivalent hashes regardless of key order" do
    Resque.enqueue FakeUniqueJob, bar: 1, foo: 2
    Resque.enqueue FakeUniqueJob, foo: 2, bar: 1
    assert_equal 1, Resque.size(:unique)
  end

  should "treat string and symbol keys equally" do
    Resque.enqueue FakeUniqueJob, bar: 1, foo: 1
    Resque.enqueue FakeUniqueJob, bar: 1, "foo" => 1
    assert_equal 1, Resque.size(:unique)
  end

  should "mark jobs as unqueued, when Job.destroy is killing them" do
    Resque.enqueue FakeUniqueJob, "foo"
    Resque.enqueue FakeUniqueJob, "foo"
    assert_equal 1, Resque.size(:unique)
    Resque::Job.destroy(:unique, FakeUniqueJob)
    assert_equal 0, Resque.size(:unique)
    Resque.enqueue FakeUniqueJob, "foo"
    Resque.enqueue FakeUniqueJob, "foo"
    assert_equal 1, Resque.size(:unique)
  end

  should "mark jobs as unqueued when they raise an exception" do
    2.times { Resque.enqueue( FailingUniqueJob, "foo" ) }
    assert_equal 1, Resque.size(:unique)
    worker = Resque::Worker.new(:unique)
    worker.work 0
    assert_equal 0, Resque.size(:unique)
    2.times { Resque.enqueue( FailingUniqueJob, "foo" ) }
    assert_equal 1, Resque.size(:unique)
  end

  should "report if a unique job is enqueued" do
    Resque.enqueue FakeUniqueJob, "foo"
    assert Resque.enqueued?(FakeUniqueJob, "foo")
    refute Resque.enqueued?(FakeUniqueJob, "bar")
  end

  should "report if a job is enqueued" do
    default_queue = FakeUniqueJob.instance_variable_get(:@queue)
    FakeUniqueJob.instance_variable_set(:@queue, :other)
    Resque.enqueue FakeUniqueJob, "foo"
    assert Resque.enqueued_in?(:other, FakeUniqueJob, "foo")
    FakeUniqueJob.instance_variable_set(:@queue, default_queue)
    refute Resque.enqueued?(FakeUniqueJob, "foo")
  end

  should "cleanup when a queue is destroyed" do
    Resque.enqueue FakeUniqueJob, "foo"
    Resque.enqueue FailingUniqueJob, "foo"
    Resque.remove_queue(:unique)
    Resque.enqueue(FakeUniqueJob, "foo")
    assert_equal 1, Resque.size(:unique)
  end

  should "honor ttl in the redis key" do
    Resque.enqueue UniqueJobWithTtl
    assert Resque.enqueued?(UniqueJobWithTtl)
    keys = Resque.redis.keys "solo:queue:unique_with_ttl:job:*"
    assert_equal 1, keys.length
    assert_in_delta UniqueJobWithTtl.ttl, Resque.redis.ttl(keys.first), 2
  end

  should "not allow the same job to be enqueued after execution if lock_after_execution_period is set" do
    Resque.enqueue UniqueJobWithLock, "foo"
    Resque.enqueue UniqueJobWithLock, "foo"
    assert_equal 1, Resque.size(:unique_with_lock)
    Resque.reserve(:unique_with_lock)
    assert_equal 0, Resque.size(:unique_with_lock)
    Resque.enqueue UniqueJobWithLock, "foo"
    assert_equal 0, Resque.size(:unique_with_lock)
  end

  should "honor lock_after_execution_period in the redis key" do
    Resque.enqueue UniqueJobWithLock
    Resque.reserve(:unique_with_lock)
    keys = Resque.redis.keys "solo:queue:unique_with_lock:job:*"
    assert_equal 1, keys.length
    assert_in_delta UniqueJobWithLock.lock_after_execution_period, Resque.redis.ttl(keys.first), 2
  end
  
end