# 
# To change this template, choose Tools | Templates
# and open the template in the editor.

require 'rubygems'
require 'rake'
# require 'echoe'
# 
# Echoe.new('metamri', '0.1.0') do |p|
#   p.description    = "Extraction of MRI metadata and insertion into compatible sqlite3 databases."
#   p.url            = "http://github.com/brainmap/metamri"
#   p.author         = "Kristopher J. Kosmatka"
#   p.email          = "kk4@medicine.wisc.edu"
#   p.ignore_pattern = ["nbproject/*"]
#   p.development_dependencies = []
# end
# 
# Dir["#{File.dirname(__FILE__)}/tasks/*.rake"].sort.each { |ext| load ext }


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
    gemspec.add_development_dependency('rspec')
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler not available. Install it with: sudo gem install jeweler"
end