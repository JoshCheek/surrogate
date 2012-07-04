require "bundler/gem_tasks"

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new :rspec do |t|
  t.rspec_opts = [
    '--fail-fast',
    '--colour',
    '--format', 'documentation',
  ]
end

require 'mountain_berry_fields/rake_task'
MountainBerryFields::RakeTask.new :test_readme, 'Readme.mountain_berry_fields.md'


task default: [:rspec, :test_readme]
