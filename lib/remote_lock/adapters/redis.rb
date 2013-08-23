require 'remote_lock/adapters/base'

module RemoteLock::Adapters
  class Redis < Base

    def store(key, expires_in_seconds)
      @connection.setnx(key_for(key), uid).tap do |status|
        @connection.expire(key_for(key), expires_in_seconds) if status
      end
    end

    def delete(key)
      @connection.del(key_for(key))
    end

    def has_key?(key)
      @connection.get(key_for(key)) == uid
    end

  end
end
