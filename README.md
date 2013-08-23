[![Build Status](https://travis-ci.org/HouseTrip/remote_lock.png)](https://travis-ci.org/HouseTrip/remote-lock)

remote_lock
===========

This is a rewrite of a initial extraction from Nick Kallen's [cache-money](http://github.com/nkallen/cache-money) and
also a fork from James Golick [memcache-lock](https://github.com/jamesgolick/memcache-lock)

This adds supports for memcache or redis as lock storage.

Installation
------------

```shell
gem install remote-lock
```

Initialization
-------------

* Lock using memcached:

  ```ruby
  # memcache = MemCache.new(YAML.load(File.read("/path/to/memcache/config")))
  # Or whatever way you have your memcache connection
  $lock = RemoteLock.new(RemoteLock::Adapters::Memcached.new(memcache))
  ```

* Lock using redis:

  ```ruby
  # redis = Redis.new
  # Or whatever way you have your redis connection
  $lock = RemoteLock.new(RemoteLock::Adapters::Redis.new(redis))
  ```

Usage
-----

Then, wherever you'd like to lock a key, use it like this:

```ruby
$lock.synchronize("some-key") do
  # stuff that needs synchronization in here
end
```

Options:

* TTL

  By default keys will expire after 60 seconds, you can define this per key:

  ```ruby
  $lock.synchronize("my-key", expiry: 30.seconds) do ... end
  ```

* Attempts

  By default it will try 11 times to lock the resource, this can be set per key:

  ```ruby
  $lock.synchronize("my-key", retries: 5) do ... end
  ```

* Tries interval

  You can customize the interval between tries, initially it's 10ms:

  ```ruby
  $lock.synchronize("my-key", initial_wait: 10e-3) do ... end
  ```

For more info, see lib/remote_lock.rb. It's very straightforward to read.

Note on Patches/Pull Requests
=============================

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but
   bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

License
============
MIT licence. Copyright (c) 2013 HouseTrip Ltd.



Based on the memcache-lock gem: https://github.com/jamesgolick/memcache-lock
