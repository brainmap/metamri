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
  
  # def file_count
  #   unless @file_count
  #     if @raw_image_files.first.dicom?
  #       @file_count = Dir.open(@directory).reject{ |branch| /^\./.match(branch) }.length
  #     elsif @raw_image_files.first.pfile?
  #       @file_count = 1
  #     else raise "File not recognized as dicom or pfile."
  #     end
  #   end
  #   return @file_count
  # end
  
  def pfile?
    scanned_file =~ /^P.{5}.7$/
  end
  
  
  
  def file_count
    if pfile?
      file_count = 1
    else
      file_count = Dir.open(path).reject{ |branch| /(^\.|.yaml$)/.match(branch) }.length
    end
    return file_count
  end
  
  # Returns a relative filepath to the dataset.  Handles dicoms by returning the
  # dataset directory, and pfiles by returning either the pfile filename or,
  # if passed a visit directory, the relative path from the visit directory to 
  # the pfile (i.e. P00000.7 or raw/P00000.7).
  def relative_dataset_path(visit_dir = nil)
    if pfile?
      relative_dataset_path = scanned_file
    else # Then it's a dicom.
      relative_dataset_path = File.basename(path)
    end
    
    return relative_dataset_path
  end
  
  # Queries ActiveResource for an array of ImageDatasetQualityCheckResources 
  def image_dataset_quality_checks
    @image_dataset_quality_checks ||= ImageDatasetQualityCheckResource.find(:all, :params => {:image_dataset_id => id })
  end
  
  def image_dataset_quality_checks_tablerow
    output = []
    unless image_dataset_quality_checks.empty?
      image_dataset_quality_checks.each do |qc|
        qc.failed_checks.each do |check|
          output << "* #{check[:name].capitalize.gsub("_", " ") } (#{check[:value]}): #{(check[:comment] + ".") if check[:comment]}"
        end

        output << "Concerns: #{qc.other_issues}" if qc.other_issues

        if output.empty? 
          output << "Good"
        end
      
        # Add QC date at end.
        output << "[#{qc.attribute_names['created_at'].strftime('%D')}]"
      end
    end
    return output.join(" ")
  end
  
  # Creates an Hirb Table for pretty output of dataset info.
  # It takes an array of either RawImageDatasets or RawImageDatasetResources
  def self.to_table(datasets)
    Hirb::Helpers::AutoTable.render(
      datasets.sort_by{ |ds| [ds.timestamp, File.basename(ds.path)] }, 
      :headers => { :relative_dataset_path => 'Dataset', :series_description => 'Series Details', :file_count => "File Count", :image_dataset_quality_checks_tablerow => "Quality Checks"}, 
      :fields => [:relative_dataset_path, :series_description, :file_count, :image_dataset_quality_checks_tablerow],
      :description => false, # Turn off rendering row count description at bottom.
      :resize => true
    )
  rescue NameError => e
    raise e

    # Header Line
    printf "\t%-15s %-30s [%s]\n", "Directory", "Series Description", "Files"

    # Dataset Lines
    datasets.sort_by{|ds| [ds.timestamp, File.basename(ds.path)] }.each do |dataset|
      printf "\t%-15s %-30s [%s]\n", dataset.relative_dataset_path, dataset.series_description, dataset.file_count
    end

    # Reminder Line
    puts "(This would be much prettier if you installed hirb.)"
    return
  end
  
end