require 'rubygems'
require 'rake'
require 'rdoc/task'
require 'rake/testtask'

require 'bundler/gem_tasks'


begin
  require 'spec/rake/spectask'
  Spec::Rake::SpecTask.new do |test|
    test.warning = true
    test.rcov = true
    test.spec_files = FileList['spec/**/*_spec.rb']
  end
rescue LoadError
  task :spec do
    abort "RSpec is not available.  In order to run specs, you must: sudo gem install rspec"
  end
end

Rake::TestTask.new do |t|
  t.libs << "test"
  t.test_files = FileList['test/*test*.rb']
  t.verbose = true
end