# frozen_string_literal: true

class FakeJob
  @queue = :normal
end

class FakeUniqueInQueue
  include Resque::Plugins::UniqueInQueue
  @queue = :unique

  def self.perform(_); end
end

class FailingUniqueInQueue
  include Resque::Plugins::UniqueInQueue
  @queue = :unique

  def self.perform(_)
    raise 'Fail'
  end
end

