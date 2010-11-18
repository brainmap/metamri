require 'rubygems'
require 'rake'
require 'rake/rdoctask'
require 'rake/testtask'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "metamri"
    gemspec.summary = "MRI metadata"
    gemspec.description = "Extraction of MRI metadata and insertion into compatible sqlite3 databases."
    gemspec.email = "kk4@medicine.wisc.edu"
    gemspec.homepage = "http://github.com/brainmap/metamri"
    gemspec.authors = ["Kristopher J. Kosmatka"]
    gemspec.add_dependency('sqlite3-ruby')
    gemspec.add_dependency('dicom')
    # gemspec.add_dependency('rmagick')
    gemspec.add_development_dependency('rspec')
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install jeweler"
end

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