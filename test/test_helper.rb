if ENV["SIMPLE_COV"]
  require "simplecov"
  SimpleCov.start
end

require "minitest/autorun"
require "resque-unique_at_enqueue"
require "fake_jobs"
require "fakeredis"
begin
  require "pry-byebug"
rescue LoadError
  # ignore
end
