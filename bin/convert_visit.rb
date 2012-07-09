#!/usr/bin/env ruby
#
# == Synopsis 
#   A simple utility for converting all the dicom datasets in a directory into niftis.  Defaults to the current
#   default preprocessed repository.
#
# == Examples
#   convert_visit.rb /Data/vtrak1/raw/ries.aware.visit1/awr001_7854_02102009 ries.aware.visit1 
#   convert_visit.rb /Data/vtrak1/raw/ries.aware.visit1/awr001_7854_02102009 ries.aware.visit1 /Data/scratch/temp_analysis/awr001
#
# == Usage 
#   convert_visit.rb <raw_data_directory> <scan_procedure_codename> 
#
#   For help use: import_visit.rb -h
#
#	  Currently, the script will create an "unknown" directory in the output 
#   directory, and will place files named after the series description in the 
#   dicom header in that directory.  
#
# == Options
#   There is currently no option parser in this script.  To be implemented.
#
# == Author
#   
#
# == Copyright
#   Copyright (c) 2009 WADRC Imaging Core.
#

$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'metamri'
require 'pathname'
require 'rdoc/usage'
require 'logger'


def convert_visit(raw_directory, scan_procedure_codename, output_directory = nil)
  $LOG = Logger.new(File.join(Dir.tmpdir, File.basename(raw_directory)))  
  v = VisitRawDataDirectory.new(raw_directory, scan_procedure_codename)
  puts "+++ Converting #{v.visit_directory} as part of #{v.scan_procedure_name} +++"
  output_directory = output_directory ||= v.default_preprocess_directory

  begin
    default_options = {:ignore_patterns => [/vipr/,/900$/,/901$/,/999$/]}  # seems to like number , not like string
    #options = default_options.merge(options)
    v.scan(default_options)
    v.to_nifti!(output_directory)
  rescue Exception => e
    puts "There was a problem scanning a dataset in #{v.visit_directory}... skipping."
    puts "Exception message: #{e.message}"
    $LOG.error "There was a problem scanning a dataset in #{v.visit_directory}... skipping."
    $LOG.error "Exception message: #{e.message}"
  ensure
    v = nil
  end
end



if File.basename(__FILE__) == File.basename($PROGRAM_NAME)
  RDoc::usage() if (ARGV[0] == '-h')
  raw_directory = ARGV[0]


  # Optional Scan Procdedure Codename
  # If not given this is inferred by VisitRawDataDirectory#get_scan_procedure_based_on_raw_directory
  scan_procedure_codename = ARGV[1] ? ARGV[1] : nil
  
  # Optional Output Directory
  # If not given this is inferred by  VisitRawDataDirectory#default_preprocess_directory
  output_directory = ARGV[2] ? ARGV[2] : nil

  convert_visit(raw_directory, scan_procedure_codename, output_directory)
end
