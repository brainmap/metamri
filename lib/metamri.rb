$: << File.dirname(__FILE__)

begin
  require 'rubygems'
  gem 'activeresource', '<= 2.3.8'
  require 'active_resource'
end


require 'metamri/core_additions'
require 'metamri/raw_image_file'
require 'metamri/raw_image_dataset'
require 'metamri/visit_raw_data_directory'
require 'metamri/raw_image_dataset_resource'
require 'metamri/visit_raw_data_directory_resource'
require 'metamri/image_dataset_quality_check_resource'

# require 'metamri/raw_image_dataset_thumbnail'
# TODO Move raw_image_dataset_thumbnail out of metamri.  

begin
  require 'hirb'
rescue LoadError
  puts "Hirb must be installed for pretty output. Use 'sudo gem install hirb'"
end

module Metamri
end
