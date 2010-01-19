#!/usr/bin/env ruby
#
# == Synopsis 
#   A simple utility for converting all the dicom datasets in a directory into niftis.  Defaults to the current
#   default preprocessed repository.
#
# == Examples
#   convert_visit.rb /Data/vtrak1/raw/ries.aware.visit1/awr001_7854_02102009 ries.aware.visit1 

#
# == Usage 
#   convert_visit.rb <raw_data_directory> <scan_procedure_codename> 
#
#   For help use: import_visit.rb -h
#
# == Options
#   -h, --help          Displays help message
#   -v, --visit         Visit raw data directory, absolute path
#   -p, --scan_procedure      scan_procedure codename, e.g. johnson.alz.visit1
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

# == Function
#   
# 
# == Usage
#   
#
# == Example
#   
#
def convert_visit(raw_directory, scan_procedure_codename, output_directory = nil)
  $LOG = Logger.new(File.join(Dir.tmpdir, File.basename(raw_directory)))  
  v = VisitRawDataDirectory.new(raw_directory, scan_procedure_codename)
  puts "+++ Converting #{v.visit_directory} as part of #{v.scan_procedure_name} +++"
  output_directory = output_directory ||= v.default_preprocess_directory

  begin
    v.scan
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

  # This is required for now, will be inferred from path in the future.
  scan_procedure_codename = ARGV[1] 
  
  output_directory = ARGV[2] ? ARGV[2] : nil

  convert_visit(raw_directory, scan_procedure_codename, output_directory)
end
