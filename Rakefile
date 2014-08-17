require 'bundler/setup'


desc 'Run specs'
task :spec do
  sh 'rspec --fail-fast --colour --format documentation'
end

desc 'Test/generate readme'
task :readme do
  sh 'bundle exec mountain_berry_fields Readme.md.mountain_berry_fields'
end


task default: [:spec, :readme]
