require 'active_resource'

#DATAPANDA_SERVER = 'http://144.92.151.228'
DATAPANDA_SERVER = 'http://localhost:3000'

class RawImageDatasetResource < ActiveResource::Base
  self.site = "http://localhost:3000"
  self.element_name = "image_dataset"
  
  # Creates a Backwards Transfer to go from ActiveRecord to Metamri Classes
  # ActiveResource will provide :attr methods for column names from the database, 
  # so check the current schema.rb file for those.
  def to_metamri_image_dataset
    # A Metamri Class requires at least one valid image file.
    # This is a little tricky since we really only care about the variables, not rescanning them.
    
    Pathname.new(path).first_dicom do |fd|
      @dataset = RawImageDataset.new( path, [RawImageFile.new(fd)] )
    end
    
    return @dataset
  end
end