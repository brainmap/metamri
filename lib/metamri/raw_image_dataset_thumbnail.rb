require 'tmpdir'
begin
  %W{dicom RMagick}.each do |lib|
    require lib
  end
rescue LoadError => e
  raise LoadError, "Could not load #{e}.  Thumbnailing will use slicer instead of ruby-dicom."
end
  

# This class is a ruby object encapsulating a .png 2D Thumbnail of a Dataset
# Initialize it with an #RawImageDataset
class RawImageDatasetThumbnail
  VALID_PROCESSORS = [:rubydicom, :slicer]

  # The parent #RawImageDataset
  attr_reader :dataset
  # The path to the thumbnail image if it's already been created
  attr_reader :path
  # The processor for creating the thumbnail (:rubydicom or :slicer)
  attr_reader :processor

  # Creates a RawImageDatasetThumbnail instance by passing in a parent dataset to thumbnail.
  def initialize(dataset)
    if dataset.class == RawImageDataset
      @dataset = dataset
    else
      raise StandardError, "Dataset #{dataset} class must be RawImageDataset."
    end
  end
  
  def thumbnail
    @path ||= create_thumbnail
  end
  
  # Creates a thumbnail image (.png or .jpg) and returns the full file path of the thumbnail.
  # Raises a ScriptError if the thumbnail could not be created.
  # Raises a StandardError if the format is incorrect (i.e. P-file instead of DICOM)
  # 
  # Be sure your filename is a valid unix filename - no spaces.
  # 
  # Returns the full absolute filename to the new thumbnail image and sets it to @path instance variable.
  # 
  # === Parameters
  # 
  # * <tt>output</tt>: An optional string which specifies a directory or filename for the thumbnail image.
  # * <tt>options</tt>: A hash of additional options.
  # 
  # === Options
  # 
  # * <tt>:processor</tt> -- Symbol. Specifies which thumbnail processor to use.  Defaults to :rubydicom, alternatively it could be :slicer
  # 
  # === Examples
  # 
  #  # Load a RawImageDataset 
  #  ds = RawImageDataset('s01_assetcal', RawImageFile.new('./s01_assetcal/I0001.dcm'))
  #  # Create a RawImageDatasetThumbnail instance
  #  thumb = RawImageDatasetThumbnail.new(ds)
  #  # Create a thumbnail in a temp directory without options, save it to a destination image, or force it to use FSL Slicer.
  #  thumb.create_thumbnail
  #  thumb.create_thumbnail('/tmp/asset_cal.png')
  #  thumb.create_thumbnail('/tmp/asset_cal.png', :processor => :slicer)
  # 
  def create_thumbnail(output = nil, options = {:processor => :rubydicom})
    raise StandardError, "Thumbnail available only for DICOM format." unless dataset.raw_image_files.first.dicom?
    raise ArgumentError, "Invalid :processor option #{options[:processor]}" unless VALID_PROCESSORS.include?(options[:processor])
    if output
      if File.directory?(output)
        # output is a directory.  Set the output directory but leave filepath nil.
        output_directory = output.escape_dirname
      else
        # output is a path.  Set the output_directory and specify that the full filepath is already complete.
        output_directory = File.dirname(output).escape_dirname
        filepath = output
      end
    else
      # If no output was given, default to a new temp directory.
      output_directory = Dir.mktmpdir
    end
    
    @processor = options[:processor]
    
    # Set a default filepath unless one was explicitly passed in.
    default_name = @dataset.series_description.escape_filename
    filepath ||= File.join(output_directory, default_name + '.png')
    
    begin
      case @processor
      when :rubydicom
        @path = create_thumbnail_with_rubydicom(filepath)
      when :slicer
        @path = create_thumbnail_with_fsl_slicer(filepath)
      end
    rescue RangeError, ScriptError => e
      unless @processor == :slicer 
        puts "Could not create thumbnail with rubydicom.  Trying FSL slicer."
        @processor = :slicer
        retry
      else 
        raise e
      end
    end
    
    raise ScriptError, "Could not create thumbnail from #{@dataset.series_description} - #{File.join(@dataset.directory, @dataset.scanned_file)}" unless @path && File.readable?(@path) 
    return @path
  end
  
  private
  
  # Creates a thumbnail using RubyDicom
  # Pass in an absolute or relative filepath, including filename and extension.
  # Returns an absolute path to the created thumbnail image.
  def create_thumbnail_with_rubydicom(output_file)
    output_file = File.expand_path(output_file)

    dicom_files = Dir.glob(File.join(dataset.directory, dataset.glob))
    if dicom_files.empty?  # Try the glob again with a zipped extension.
      dicom_files = Dir.glob(File.join(dataset.directory, dataset.glob) + '*.bz2')
    end
    if dicom_files.empty? # If still empty...
      raise StandardError, "Could not find dicom files using #{dataset.glob} in #{dataset.directory}"
    end
    dicom_file = Pathname(dicom_files[dicom_files.size/2])
    dicom_file.local_copy do |lc|
      dcm = DICOM::DObject.new(lc.to_s)
      raise ScriptError, "Could not read dicom #{dicom_file.to_s}" unless dcm.read_success
      image = dcm.get_image_magick(:rescale => true)
      raise ScriptError, "RubyDicom did not return an image array (this is probably a color image)." unless image.kind_of? Magick::Image
      image.write(output_file)
    end

    raise(ScriptError, "Error creating thumbnail #{output_file}") unless File.exist?(output_file)

    return output_file
  end
  
  # Creates a thumbnail using FSL's Slicer bash utility.
  # Pass in an output filepath.
  def create_thumbnail_with_fsl_slicer(output_file)
    nii_tmpdir = Dir.mktmpdir
    nifti_output_file = File.basename(output_file, File.extname(output_file)) + '.nii'
    Pathname.new(dataset.directory).all_dicoms do |dicom_files| 
      # First Create a Nifti File to read 
      @dataset.to_nifti!(nii_tmpdir, nifti_output_file, {:input_directory => File.dirname(dicom_files.first)} )
    end
    # Then create the .png
    `slicer #{File.join(nii_tmpdir, nifti_output_file)} -a #{output_file}`
    
    raise(ScriptError, "Error creating thumbnail #{output_file}") unless File.exist?(output_file)
    
    return output_file
  end
  
end
