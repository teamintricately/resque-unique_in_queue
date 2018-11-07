require "test_helper"

class JobTest < MiniTest::Spec
  before do
    Resque.redis.redis.flushdb
  end

  it "enqueue identical jobs once" do
    Resque.enqueue FakeUniqueAtEnqueue, "x"
    Resque.enqueue FakeUniqueAtEnqueue, "x"
    assert_equal 1, Resque.size(:unique)
  end

  it "allow the same jobs to be executed one after the other" do
    Resque.enqueue FakeUniqueAtEnqueue, "foo"
    Resque.enqueue FakeUniqueAtEnqueue, "foo"
    assert_equal 1, Resque.size(:unique)
    Resque.reserve(:unique)
    assert_equal 0, Resque.size(:unique)
    Resque.enqueue FakeUniqueAtEnqueue, "foo"
    Resque.enqueue FakeUniqueAtEnqueue, "foo"
    assert_equal 1, Resque.size(:unique)
  end

  it "consider equivalent hashes regardless of key order" do
    Resque.enqueue FakeUniqueAtEnqueue, bar: 1, foo: 2
    Resque.enqueue FakeUniqueAtEnqueue, foo: 2, bar: 1
    assert_equal 1, Resque.size(:unique)
  end

  it "treat string and symbol keys equally" do
    Resque.enqueue FakeUniqueAtEnqueue, bar: 1, foo: 1
    Resque.enqueue FakeUniqueAtEnqueue, bar: 1, "foo" => 1
    assert_equal 1, Resque.size(:unique)
  end

  it "mark jobs as unqueued, when Job.destroy is killing them" do
    Resque.enqueue FakeUniqueAtEnqueue, "foo"
    Resque.enqueue FakeUniqueAtEnqueue, "foo"
    assert_equal 1, Resque.size(:unique)
    Resque::Job.destroy(:unique, FakeUniqueAtEnqueue)
    assert_equal 0, Resque.size(:unique)
    Resque.enqueue FakeUniqueAtEnqueue, "foo"
    Resque.enqueue FakeUniqueAtEnqueue, "foo"
    assert_equal 1, Resque.size(:unique)
  end

  it "mark jobs as unqueued when they raise an exception" do
    2.times { Resque.enqueue(FailingUniqueAtEnqueue, "foo") }
    assert_equal 1, Resque.size(:unique)
    worker = Resque::Worker.new(:unique)
    worker.work 0
    assert_equal 0, Resque.size(:unique)
    2.times { Resque.enqueue(FailingUniqueAtEnqueue, "foo") }
    assert_equal 1, Resque.size(:unique)
  end

  it "report if a unique job is enqueued" do
    Resque.enqueue FakeUniqueAtEnqueue, "foo"
    assert Resque.enqueued?(FakeUniqueAtEnqueue, "foo")
    refute Resque.enqueued?(FakeUniqueAtEnqueue, "bar")
  end

  it "report if a unique job is enqueued in another queue" do
    default_queue = FakeUniqueAtEnqueue.instance_variable_get(:@queue)
    FakeUniqueAtEnqueue.instance_variable_set(:@queue, :other)
    Resque.enqueue FakeUniqueAtEnqueue, "foo"
    assert Resque.enqueued_in?(:other, FakeUniqueAtEnqueue, "foo")
    FakeUniqueAtEnqueue.instance_variable_set(:@queue, default_queue)
    refute Resque.enqueued?(FakeUniqueAtEnqueue, "foo")
  end

  it "cleanup when a queue is destroyed" do
    Resque.enqueue FakeUniqueAtEnqueue, "foo"
    Resque.enqueue FailingUniqueAtEnqueue, "foo"
    Resque.remove_queue(:unique)
    Resque.enqueue(FakeUniqueAtEnqueue, "foo")
    assert_equal 1, Resque.size(:unique)
  end

  it "honor ttl in the redis key" do
    Resque.enqueue UniqueAtEnqueueWithTtl
    assert Resque.enqueued?(UniqueAtEnqueueWithTtl)
    keys = Resque.redis.keys "unique_at_enqueue:queue:unique_with_ttl:job:*"
    assert_equal 1, keys.length
    assert_in_delta UniqueAtEnqueueWithTtl.ttl, Resque.redis.ttl(keys.first), 2
  end

  it "prevents duplicates within lock_after_execution_period" do
    Resque.enqueue UniqueAtEnqueueWithLock, "foo"
    Resque.enqueue UniqueAtEnqueueWithLock, "foo"
    assert_equal 1, Resque.size(:unique_with_lock)
    Resque.reserve(:unique_with_lock)
    assert_equal 0, Resque.size(:unique_with_lock)
    Resque.enqueue UniqueAtEnqueueWithLock, "foo"
    assert_equal 0, Resque.size(:unique_with_lock)
  end

  it "honor lock_after_execution_period in the redis key" do
    Resque.enqueue UniqueAtEnqueueWithLock
    Resque.reserve(:unique_with_lock)
    keys = Resque.redis.keys "unique_at_enqueue:queue:unique_with_lock:job:*"
    assert_equal 1, keys.length
    assert_in_delta UniqueAtEnqueueWithLock.lock_after_execution_period,
                    Resque.redis.ttl(keys.first), 2
  end
end
