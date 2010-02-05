require 'active_resource'

class RawImageDatasetResource < ActiveResource::Base
  self.site = VisitRawDataDirectory::DATAPANDA_SERVER
  self.element_name = "image_dataset"
  
  # Creates a Backwards Transfer to go from ActiveRecord to Metamri Classes
  # ActiveResource will provide :attr methods for column names from the database, 
  # so check the current schema.rb file for those.
  def to_metamri_raw_image_dataset
    # A Metamri Class requires at least one valid image file.
    # This is a little wasteful since we really only care about the variables, 
    # not rescanning them.
    
    filename = Pathname.new(File.join(path, scanned_file))
    filename_matches = /P\d{5}.7(.bz2)?/.match(filename)
    
    if filename_matches    # Pfile
      if filename_matches[1] # '.bz2' if present, nil if otherwise.
        filename = Pathname.new(File.join(filename, '.bz2'))
      end
            
      # The scanned file is always reported in unzipped format, so we don't
      # have to worry about stripping a .bz2 extension.
      # The actual file on the filesystem may be zipped or unzipped 
      # (although it Should! be zipped.  Check for that or return IOError.
      zipped_filename = filename.to_s.chomp + '.bz2'

      if filename.file?
        image_file = filename
      elsif Pathname.new(zipped_filename).file?
        image_file = Pathname.new(zipped_filename)
      else 
        raise IOError, "Could not find #{filename} or it's bz2 zipped equivalent #{zipped_filename}."
      end
      
      image_file.local_copy do |local_pfile| 
        @dataset = RawImageDataset.new( path, [RawImageFile.new(local_pfile)])
      end

    else # Dicom      
      Pathname.new(path).first_dicom do |fd|
        @dataset = RawImageDataset.new( path, [RawImageFile.new(fd)] )
      end
    end
    
    return @dataset
  end
  
  # Map RawImageDatasetResource and RawImageDataset
  # def method_missing(m, *args, &block)
  #   puts m
  #   if m == :directory
  #     path
  #   elsif m == :directory_basename
  #     File.basename(directory)
  #   else
  #     super
  #   end
  # end
end