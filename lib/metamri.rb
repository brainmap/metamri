$: << File.dirname(__FILE__)

require 'raw_image_file'
require 'raw_image_dataset'
require 'visit_raw_data_directory'
require 'metamri/core_additions'
require 'metamri/raw_image_dataset_resource'
require 'metamri/visit_raw_data_directory_resource'

begin
  require 'hirb'
rescue LoadError
  puts "Hirb must be installed for pretty output. Use 'sudo gem install hirb'"
end

module Metamri
end
