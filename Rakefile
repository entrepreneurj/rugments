require 'pathname'

task :test do
  sh 'bundle exec rspec spec'
end

task :doc do
  sh 'bundle exec yard'
end

namespace :doc do
  task :server do
    sh 'bundle exec yard server --reload'
  end

  task :clean do
    sh 'rm -rf doc coverage .yardoc'
  end
end

task build: [:clean, :spec] do
  puts
  sh 'gem build rouge.gemspec'
end

task default: :test

# Load rake tasks from tasks subdirectory.
root_path = File.expand_path(File.dirname(__FILE__))
Dir.glob(File.join(root_path, 'tasks/*.rake')) { |f| load f }
