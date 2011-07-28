$: << File.dirname(__FILE__)


begin
  require 'rubygems'
  require "bundler/setup"
  require 'active_resource'
  require 'hirb'
  require 'rspec'
  require 'dicom'
  require 'rmagick'
rescue LoadError
end


require 'metamri/core_additions'
require 'metamri/raw_image_file'
require 'metamri/raw_image_dataset'
require 'metamri/visit_raw_data_directory'
require 'metamri/raw_image_dataset_resource'
require 'metamri/visit_raw_data_directory_resource'
require 'metamri/image_dataset_quality_check_resource'
require 'metamri/dicom_additions'
require 'metamri/raw_image_dataset_thumbnail'
require 'fileutils'

# TODO Move raw_image_dataset_thumbnail out of metamri.  

begin
  require 'hirb'
rescue LoadError
  puts "Hirb must be installed for pretty output. Use 'sudo gem install hirb'"
end

# module Metamri; end
