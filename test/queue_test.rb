require 'test_helper'

class QueueTest < MiniTest::Spec
  describe '.is_unique?' do
    it 'is false for non-unique job' do
      refute Resque::UniqueAtEnqueue::Queue.is_unique?(class: 'FakeJob')
    end

    it 'is false for invalid job class' do
      refute Resque::UniqueAtEnqueue::Queue.is_unique?(class: 'InvalidJob')
    end

    it 'is true for unique job' do
      assert Resque::UniqueAtEnqueue::Queue.is_unique?(class: 'FakeUniqueAtEnqueue')
    end
  end

  describe '.item_ttl' do
    it 'is -1 for non-unique job' do
      assert_equal(-1, Resque::UniqueAtEnqueue::Queue.item_ttl(class: 'FakeJob'))
    end

    it 'is -1 for invalid job class' do
      assert_equal(-1, Resque::UniqueAtEnqueue::Queue.item_ttl(class: 'InvalidJob'))
    end

    it 'is -1 for unique job' do
      assert_equal(-1, Resque::UniqueAtEnqueue::Queue.item_ttl(class: 'FakeUniqueAtEnqueue'))
    end

    it 'is job TTL' do
      assert_equal 300, UniqueAtEnqueueWithTtl.ttl
      assert_equal 300, Resque::UniqueAtEnqueue::Queue.item_ttl(class: 'UniqueAtEnqueueWithTtl')
    end
  end

  describe '.lock_after_execution_period' do
    it 'is 0 for non-unique job' do
      assert_equal 0, Resque::UniqueAtEnqueue::Queue.lock_after_execution_period(class: 'FakeJob')
    end

    it 'is 0 for invalid job class' do
      assert_equal 0, Resque::UniqueAtEnqueue::Queue.lock_after_execution_period(class: 'InvalidJob')
    end

    it 'is 0 for unique job' do
      assert_equal 0, Resque::UniqueAtEnqueue::Queue.lock_after_execution_period(class: 'FakeUniqueAtEnqueue')
    end

    it 'is job lock period' do
      assert_equal 150, UniqueAtEnqueueWithLock.lock_after_execution_period
      assert_equal 150, Resque::UniqueAtEnqueue::Queue.lock_after_execution_period(class: 'UniqueAtEnqueueWithLock')
    end
  end
end
