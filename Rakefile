require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:spec)

RuboCop::RakeTask.new(:rubocop) do |t|
  t.options = ['--display-cop-names']
end

desc 'Run rubocop and rspec'
task :ci do
  Rake::Task["spec"].invoke
  Rake::Task["rubocop"].invoke
end

task default: :ci
