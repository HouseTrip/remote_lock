def redis
  $redis ||= Redis.new()
end
