class RemoteLock
  class Error < RuntimeError; end

  DEFAULT_OPTIONS = {
    :initial_wait => 10e-3, # seconds -- first soft fail will wait for 10ms
    :expiry       => 60,    # seconds
    :retries      => 11,    # these defaults will retry for a total 41sec max
  }

  def initialize(adapter, prefix = nil)
    raise "Invalid Adapter" unless Adapters::Base.valid?(adapter)
    @adapter = adapter
    @prefix = prefix
  end

  def synchronize(key, options={})
    if acquired?(key)
      yield
    else
      acquire_lock(key, options)
      begin
        yield
      ensure
        release_lock(key)
      end
    end
  end

  def acquire_lock(key, options = {})
    options = DEFAULT_OPTIONS.merge(options)
    1.upto(options[:retries]) do |attempt|
      success = @adapter.store(key_for(key), options[:expiry])
      return if success
      break if attempt == options[:retries]
      Kernel.sleep(2 ** (attempt + rand - 1) * options[:initial_wait])
    end
    raise RemoteLock::Error, "Couldn't acquire lock for: #{key}"
  end

  def release_lock(key)
    @adapter.delete(key_for(key))
  end

  def acquired?(key)
    @adapter.has_key?(key_for(key))
  end

  private

  def key_for(string)
    [@prefix, "lock", string].compact.join('/')
  end

end

require 'remote_lock/adapters/memcached'
require 'remote_lock/adapters/redis'
