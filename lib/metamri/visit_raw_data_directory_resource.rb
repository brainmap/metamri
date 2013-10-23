# encoding: utf-8
$:.unshift File.dirname(__FILE__)
require 'raw_image_dataset_resource'

class VisitRawDataDirectoryResource < ActiveResource::Base
  self.site = VisitRawDataDirectory::DATAPANDA_SERVER
  self.element_name = "visit"
  
  # Creates a Backwards Transfer to go from ActiveRecord to Metamri Classes
  #
  # ActiveResource will provide :attr methods for column names from the 
  # database, so check the current schema.rb file for those.
  def to_metamri_visit_raw_data_directory    
    @visit = VisitRawDataDirectory.new(path)
    @visit.timestamp = date
    @visit.rmr_number = rmr
    @visit.scanner_source = scanner_source
    @visit.database_id = id
    return @visit
  end
  
  def datasets
    @datasets ||= RawImageDatasetResource.find(:all, :from => RawImageDatasetResource.collection_path('search[visit_id_eq]' => "#{id}"))
  end
  
  # Convert a Resource and its datasets to a VisitRawDataDirectory and 
  # RawImageDataset, respectively, then pretty print it using
  # VisitRawDataDirectory.to_s
  # def to_s
  #   metamri_visit = to_metamri_visit_raw_data_directory
  #   metamri_visit.datasets = datasets.collect { |ds| ds.to_metamri_raw_image_dataset}
  #   metamri_visit.to_s
  # end
  
  def to_s
    puts; path.length.times { print "-" }; puts
    puts "#{path}"
    puts "#{rmr} - #{date} - #{scanner_source}"
    puts
    # puts "#{@scan_procedure_name}"
    puts RawImageDatasetResource.to_table(datasets)
    puts "Notes: " + notes unless notes.nil? or notes.empty?
    puts "#{VisitRawDataDirectory::DATAPANDA_SERVER}/visits/#{id}"
  end
  
end
