require 'cucumber'
require 'cucumber/rake/task'

task :features => :compile

Cucumber::Rake::Task.new(:features) do |t|
  t.cucumber_opts = "--format pretty"
end