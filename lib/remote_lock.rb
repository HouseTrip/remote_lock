class RemoteLock
  class Error < RuntimeError; end

  DEFAULT_OPTIONS = {
    :initial_wait => 10e-3, # seconds -- first soft fail will wait for 10ms
    :expiry       => 60,    # seconds,
    :retry_step   => 1      # seconds to wait before retrying after first try
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
    attempts = 0
    retrying_time = 0
    while true do
      attempts += 1
      success = @adapter.store(key_for(key), options[:expiry])
      return if success
      retrying_time += waiting_time(attempts, options)
      break if retrying_time >= options[:expiry]
      Kernel.sleep(retrying_time)
    end
    raise RemoteLock::Error, "Couldn't acquire lock for: #{key} - Retried for #{retrying_time} seconds in #{attempts} attempt(s)"
  end

  def waiting_time(attempts, options)
    attempts == 1 ? options[:initial_wait] : options[:retry_step]
  end

  def release_lock(key)
    @adapter.delete(key_for(key))
  end

  def acquired?(key)
    @adapter.has_key?(key_for(key))
  end

  private

  def key_for(string)
    [@prefix, "lock", string].compact.join('|')
  end

end

require 'remote_lock/adapters/memcached'
require 'remote_lock/adapters/redis'
