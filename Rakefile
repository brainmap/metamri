require 'rubygems'
require 'rake'
require 'rdoc/task'
require 'rake/testtask'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.name = "metamri"
    gemspec.summary = "MRI metadata"
    gemspec.description = "Extraction of MRI metadata and insertion into compatible sqlite3 databases."
    gemspec.email = "kk4@medicine.wisc.edu"
    gemspec.homepage = "http://github.com/brainmap/metamri"
    gemspec.authors = ["Kristopher J. Kosmatka", "Erik Kastman"]
    gemspec.add_dependency('sqlite3', '~>1.3.3')
    gemspec.add_dependency('dicom', '~>0.8')
    gemspec.add_dependency('activeresource', '~>3.0')
    gemspec.add_development_dependency('rspec', '~>2.5')

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