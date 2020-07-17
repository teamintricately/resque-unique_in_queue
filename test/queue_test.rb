# frozen_string_literal: true

require 'test_helper'

class QueueTest < MiniTest::Spec
  describe '.is_unique?' do
    it 'is false for non-unique job' do
      refute Resque::UniqueInQueue::Queue.is_unique?(class: 'FakeJob')
    end

    it 'is false for invalid job class' do
      refute Resque::UniqueInQueue::Queue.is_unique?(class: 'InvalidJob')
    end

    it 'is true for unique job' do
      assert Resque::UniqueInQueue::Queue.is_unique?(class: 'FakeUniqueInQueue')
    end
  end
end
