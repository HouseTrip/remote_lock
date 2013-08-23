require "bundler/gem_tasks"
require 'rspec/core/rake_task'
require 'rdoc/task'


desc 'Run spec tests'
task :spec do
  RSpec::Core::RakeTask.new do |spec|
    spec.pattern = "./spec/**/*_spec.rb"
  end
end

task :default => :spec

Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION')
    version = File.read('VERSION')
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "memcache-lock #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
