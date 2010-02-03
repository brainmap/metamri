require 'active_resource'

DATAPANDA_SERVER = 'http://144.92.151.228'

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
end