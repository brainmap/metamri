#!/usr/bin/env ruby
#
# == Synopsis 
#
# == Examples
#
# == Usage
#
# == Options
#
# == Author
#   
# == Copyright
#   Copyright (c) 2010 WADRC Imaging Core.
#

$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'metamri'
require 'pathname'
require 'rdoc/usage'
require 'logger'

# Assumptions: Respiratory files are large and in order.
def match_respiratory_files(path)
  #File.join(Dir.tmpdir, File.basename(path), DateTime.now.to_s)
  $LOG = Logger.new($stdout)  
  $LOG.level = Logger::INFO
  path = File.expand_path(path)
  
  raw_directory = '/tmp/awr001_7854_02102009'
  visit = VisitRawDataDirectory.new(raw_directory)
  visit.scan
  visit_epi_files = Array.new
  visit.datasets.each do |dataset|
    $LOG.debug dataset.series_description
    visit_epi_files << dataset.directory if dataset.series_description =~ /fMRI/i
  end
  $LOG.debug visit_epi_files
  
  large_files = Array.new
  
  Dir.open(path) do |dir|
    dir.each do |file|
      next if File.directory?(file)
      if file =~ /^ECGData.*/
        line_count = open(file) { |f| f.readlines}.length
        large_files << file if line_count >= 1000
        $LOG.debug "#{file}, #{line_count}"
      end
    end
  end
  $LOG.debug large_files
  
  timestamps = Array.new
  
  large_files.each do |large_file|
    timestamps << large_file.gsub(/ECGData_epiRT_/, '')
  end

  $LOG.debug timestamps
  
  return visit_epi_files.zip(timestamps)
end

def create_spec
  spec_file = 'respiratory_fixtures.yaml'
  
  runs = YAML::load_file(spec_file)
  
  runs.each do |run|
      options = [['--card', run['cardiac_data']], ['--resp', run['respiratory_data']], ['--ox', run['cardiac_trigger']]]
      system("PhysioNoise.py #{options.flatten.join(" ")}")
  end
  
end


if File.basename(__FILE__) == File.basename($PROGRAM_NAME)
  RDoc::usage() if (ARGV[0] == '-h')
  path = ARGV[0]

  resp_files = match_respiratory_files(path)
  resp_files.each do |resp_file|
    puts "#{resp_file[0]}, #{resp_file[1]}"
  end
end