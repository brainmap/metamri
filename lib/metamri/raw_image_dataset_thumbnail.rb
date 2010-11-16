require 'dicom'
require 'RMagick'
require 'tmpdir'

# This class is a ruby object encapsulating a .png 2D Thumbnail of a Dataset
class RawImageDatasetThumbnail

  attr_reader :dataset, :path

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
  
  # Returns the path of png and sets the instance variable 'path' after successfull creation.
  # Raises a ScriptError if the thumbnail could not be created.
  # Raises a StandardError if the format is incorrect (i.e. P-file instead of DICOM)
  # 
  # Be sure your filename is a valid unix filename - no spaces.
  #
  # Sets the @path instance variable and returns the full filename to the thumbnail.
  def create_thumbnail(output = nil)
    raise StandardError, "Thumbnail available only for DICOM format." unless dataset.raw_image_files.first.dicom?
    if output
      if File.directory?(output)
        output_directory = output.escape_dirname
      else
        output_directory = File.dirname(output).escape_dirname
        png_filepath = output
      end
    else
      output_directory = Dir.mktmpdir
    end
    name = @dataset.series_description.escape_filename
    puts png_filepath ||= File.join(output_directory, name + '.png')
    nifti_filepath ||=  File.join(output_directory, name + '.nii')
    
    begin
      @path = create_thumbnail_with_rubydicom(png_filepath)
    rescue RangeError, ScriptError => e
      puts "Could not create thumbnail with rubydicom.  Trying FSL slicer."
      @path = create_thumbnail_with_fsl_slicer(output_directory, nifti_filepath, png_filepath)
    end
    
    return @path
  end
  
  private
  
  def create_thumbnail_with_rubydicom(output_file)
    puts "ruby-dicom: " + output_file.to_s
    
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

    return output_file
  end
  
  def create_thumbnail_with_fsl_slicer(output_directory, nifti_filepath, png_filepath)
    Pathname.new(dataset.directory).all_dicoms do |dicom_files| 
      # First Create a Nifti File to read 
      @dataset.to_nifti!(output_directory, File.basename(png_filepath), {:input_directory => File.dirname(dicom_files.first)} )
    end
    
    # Then create the .png
    `slicer #{nifti_filepath} -a #{png_filepath}`
    
    raise(ScriptError, "Error creating thumbnail #{png_filepath}") unless File.exist?(png_filepath)
    
    return png_filepath
  end
  
end
