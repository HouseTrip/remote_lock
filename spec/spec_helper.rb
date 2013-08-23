$:.unshift(File.dirname(__FILE__))
$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'remote_lock'
require 'memcache'
require 'redis'

require "rspec"
require "rspec/core"
require 'rspec/core/rake_task'
require 'yaml'

Dir.glob(File.join(File.dirname(__FILE__), 'support/**/*.rb')).each do |file|
  require file
end

RSpec.configure do |config|
  config.before :each do
    memcache.flush_all
    redis.flushdb
  end
end
