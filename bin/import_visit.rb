#!/usr/bin/env ruby
#
# == Synopsis 
#   A simple utility for importing imaging data collected during one visit into the WADRC Data Tools web
#   application.  Data from a visit is contained in one big directory that may have many subdirectories.
#   Each individual imaging scan may be composed of an entire directory of dicom files or one single p-file.
#   This utility scans through all of the image data sets and retrieved meta-data about the scans from their
#   header information.
#
# == Examples
#   import_visit.rb /Data/vtrak1/raw/alz_2000/alz001 johnson.alz.visit1 /path/to/the/rails/db/production.sqlite3
#   import_visit.rb /Data/vtrak1/raw/wrap140/wrp001_5917_03042008 johnson.wrap140.visit1 /path/to/the/rails/db/production.sqlite3
#
# == Usage 
#   import_visit.rb <raw_data_directory> <scan_procedure_codename> <database_file>
#
#   For help use: import_visit.rb -h
#
# == Options
#   -h, --help          Displays help message
#   -v, --visit         Visit raw data directory, absolute path
#   -p, --scan_procedure      scan_procedure codename, e.g. johnson.alz.visit1
#   -d, --database      Database file into which information will imported
#
# == Author
#   K.J. Kosmatka, kk4@medicine.wisc.edu
#
# == Copyright
#   Copyright (c) 2009 WADRC Imaging Core.
#

$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'visit_raw_data_directory'
require 'pathname'
require 'rdoc/usage'
require 'logger'

# == Function
#   Imports imaging data collected during a single visit into the WADRC Data Tools web application database.
# 
# == Usage
#   import_visit(raw_directory, scan_procedure_codename, database)
#
# == Example
#   import_visit('/Data/vtrak1/raw/alz_2000/alz001','johnson.alz.visit1','/path/to/the/rails/db/production.sqlite3')
#
def import_visit(raw_directory, scan_procedure_codename, database)
  log = Logger.new(File.basename(raw_directory))  
  v = VisitRawDataDirectory.new(raw_directory, scan_procedure_codename)
  puts "+++ Importing #{v.visit_directory} as part of #{v.scan_procedure_name} +++"
  begin
    v.scan
    v.db_insert!(database)
  rescue Exception => e
    puts "There was a problem scanning a dataset in #{v.visit_directory}... skipping."
    puts "Exception message: #{e.message}"
    log.error "There was a problem scanning a dataset in #{v.visit_directory}... skipping."
    log.error "Exception message: #{e.message}"
  ensure
    v = nil
  end
end



if File.basename(__FILE__) == File.basename($PROGRAM_NAME)
  RDoc::usage() if (ARGV[0] == '-h' or ARGV.size != 3)
  raw_directory = ARGV[0]
  scan_procedure_codename = ARGV[1]
  database = ARGV[2]
  raise(IOError, "Database #{database} not writable or doesn't exist.") unless File.writable?(database)
  import_visit(raw_directory, scan_procedure_codename, database)
end
