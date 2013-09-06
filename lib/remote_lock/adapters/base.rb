require 'securerandom'

module RemoteLock::Adapters
  class Base

    def initialize(connection)
      @connection = connection
    end

    def store(key, options = {})
      raise NotImplementedError
    end

    def has_key?(key, options = {})
      raise NotImplementedError
    end

    def delete(key)
      raise NotImplementedError
    end

    def self.valid?(adapter)
      adapter.respond_to?(:store) &&
        adapter.respond_to?(:has_key?) &&
        adapter.respond_to?(:delete)
    end

    private

    # Globally unique ID for the current thread (or close enough)
    def uid
      "#{Socket.gethostname}-#{Process.pid}-#{thread_id}"
    end

    def thread_id
      Thread.current[:thread_uid] ||= SecureRandom.hex(4)
    end

  end
end
