$:.unshift File.dirname(__FILE__)

require 'active_resource'
require 'raw_image_dataset_resource'

class VisitRawDataDirectoryResource < ActiveResource::Base
  self.site = VisitRawDataDirectory::DATAPANDA_SERVER
  self.element_name = "visit"
  
  # Creates a Backwards Transfer to go from ActiveRecord to Metamri Classes
  # ActiveResource will provide :attr methods for column names from the database, 
  # so check the current schema.rb file for those.
  def to_metamri_visit_raw_data_directory    
    @visit = VisitRawDataDirectory.new(path)
    @visit.timestamp = date
    @visit.rmr_number = rmr
    @visit.scanner_source = scanner_source
    @visit.database_id = id
    return @visit
  end
  
  def datasets
    @datasets ||= RawImageDatasetResource.find(:all, :from => "/visits/#{id}/image_datasets.xml" )
  end
  
  def to_s
    metamri_visit = to_metamri_visit_raw_data_directory
    metamri_visit.datasets = datasets.collect { |ds| ds.to_metamri_raw_image_dataset}
    metamri_visit.to_s
  end
end

