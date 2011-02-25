# begin
  # require 'spec'
# rescue LoadError
  # require 'rubygems' unless ENV['NO_RUBYGEMS']
  # gem 'rspec'
  # require 'spec'
# end

require 'tmpdir'
require 'fileutils'
require 'yaml'
require 'pp'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

$MRI_DATA = ENV['MRI_DATA'] || '/Data/vtrak1/raw/test/fixtures/metamri'
