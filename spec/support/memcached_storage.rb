def memcache
  return $memcache if $memcache
  config = YAML.load(IO.read((File.expand_path(File.join(File.dirname(__FILE__) , "../memcache.yml")))))['test']
  $memcache = MemCache.new(config)
  $memcache.servers = config['servers']
  $memcache
end
