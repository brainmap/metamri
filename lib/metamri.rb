$: << File.dirname(__FILE__)

require 'raw_image_file'
require 'raw_image_dataset'
require 'visit_raw_data_directory'
require 'metamri/core_additions'
require 'metamri/raw_image_dataset_resource'

begin
  require 'hirb'
rescue LoadError => e
  puts "Hirb must be installed for pretty output. Use 'sudo gem install hirb'"
end

module Metamri
end
