# frozen_string_literal: true

require 'test_helper'

class JobTest < MiniTest::Spec
  before do
    Resque.redis.redis.flushdb
  end

  it 'enqueue identical jobs once' do
    Resque.enqueue FakeUniqueInQueue, 'x'
    Resque.enqueue FakeUniqueInQueue, 'x'
    byebug
    assert_equal 1, Resque.size(:unique)
  end

  it 'allow the same jobs to be executed one after the other' do
    Resque.enqueue FakeUniqueInQueue, 'foo'
    Resque.enqueue FakeUniqueInQueue, 'foo'
    assert_equal 1, Resque.size(:unique)
    Resque.reserve(:unique)
    assert_equal 0, Resque.size(:unique)
    Resque.enqueue FakeUniqueInQueue, 'foo'
    Resque.enqueue FakeUniqueInQueue, 'foo'
    assert_equal 1, Resque.size(:unique)
  end

  it 'consider equivalent hashes regardless of key order' do
    Resque.enqueue FakeUniqueInQueue, bar: 1, foo: 2
    Resque.enqueue FakeUniqueInQueue, foo: 2, bar: 1
    assert_equal 1, Resque.size(:unique)
  end

  it 'treat string and symbol keys equally' do
    Resque.enqueue FakeUniqueInQueue, bar: 1, foo: 1
    Resque.enqueue FakeUniqueInQueue, bar: 1, 'foo' => 1
    assert_equal 1, Resque.size(:unique)
  end

  it 'mark jobs as unqueued, when Job.destroy is killing them' do
    Resque.enqueue FakeUniqueInQueue, 'foo'
    Resque.enqueue FakeUniqueInQueue, 'foo'
    assert_equal 1, Resque.size(:unique)
    Resque::Job.destroy(:unique, FakeUniqueInQueue)
    assert_equal 0, Resque.size(:unique)
    Resque.enqueue FakeUniqueInQueue, 'foo'
    Resque.enqueue FakeUniqueInQueue, 'foo'
    assert_equal 1, Resque.size(:unique)
  end

  it 'mark jobs as unqueued when Resque processes them' do
    Resque.enqueue FakeUniqueInQueue, 'foo'
    assert Resque.enqueued?(FakeUniqueInQueue, 'foo')
    Resque.reserve(:unique)
    refute Resque.enqueued?(FakeUniqueInQueue, 'foo')
  end

  it 'mark jobs as unqueued when they raise an exception' do
    2.times { Resque.enqueue(FailingUniqueInQueue, 'foo') }
    assert_equal 1, Resque.size(:unique)
    worker = Resque::Worker.new(:unique)
    worker.work 0
    assert_equal 0, Resque.size(:unique)
    2.times { Resque.enqueue(FailingUniqueInQueue, 'foo') }
    assert_equal 1, Resque.size(:unique)
  end

  it 'report if a unique job is enqueued' do
    Resque.enqueue FakeUniqueInQueue, 'foo'
    assert Resque.enqueued?(FakeUniqueInQueue, 'foo')
    refute Resque.enqueued?(FakeUniqueInQueue, 'bar')
  end

  it 'report if a unique job is enqueued in another queue' do
    default_queue = FakeUniqueInQueue.instance_variable_get(:@queue)
    FakeUniqueInQueue.instance_variable_set(:@queue, :other)
    Resque.enqueue FakeUniqueInQueue, 'foo'
    assert Resque.enqueued_in?(:other, FakeUniqueInQueue, 'foo')
    FakeUniqueInQueue.instance_variable_set(:@queue, default_queue)
    refute Resque.enqueued?(FakeUniqueInQueue, 'foo')
  end

  it 'cleanup when a queue is destroyed' do
    Resque.enqueue FakeUniqueInQueue, 'foo'
    Resque.enqueue FailingUniqueInQueue, 'foo'
    Resque.remove_queue(:unique)
    refute Resque.enqueued?(FakeUniqueInQueue, 'foo')
    refute Resque.enqueued?(FailingUniqueInQueue, 'foo')

    Resque.enqueue(FakeUniqueInQueue, 'foo')
    assert_equal 1, Resque.size(:unique)
  end
end
