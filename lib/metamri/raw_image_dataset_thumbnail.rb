require 'dicom'
require 'rmagick'
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
  def create_thumbnail(output = nil)
    raise StandardError, "Thumbnail available only for DICOM format." unless dataset.raw_image_files.first.dicom?
    if output
      if File.directory?(output)
        output_directory = output.escape_filename
      else
        output_directory = File.dirname(output).escape_filename
        png_filename = File.basename(output).escape_filename
      end
    else
      output_directory = Dir.mktmpdir
    end
    name = @dataset.series_description.escape_filename
    png_filename ||= File.join(output_directory, name + '.png')
    nifti_filename ||=  File.join(output_directory, name + '.nii')
    
    begin
      create_thumbnail_with_rubydicom(png_filename)
    rescue ScriptError => e
      puts "Could not create thumbnail with rubydicom.  Trying FSL slicer."
      create_thumbnail_with_fsl_slicer(output_directory, nifti_filename, png_filename)
    end
    
    return png_filename
  end
  
  private
  
  def create_thumbnail_with_rubydicom(output_file = nil)
    unless output_file && File.writable?(File.dirname(output_file))
      output_file = File.join(Dir.mktmpdir, dataset.series_description.escape_filename + '.jpg')
    end

    dicom_files = Dir.glob(File.join(dataset.directory, dataset.glob))
    dicom_file = Pathname(dicom_files[dicom_files.size/2])
    dicom_file.local_copy do |lc|
      dcm = DICOM::DObject.new(lc.to_s)
      raise ScriptError, "Could not read dicom #{dicom_file.to_s}" unless dcm.read_success
      image = dcm.get_image_magick(:rescale => true)
      image[0].write(output_file)
    end

    return output_file
  end
  
  def create_thumbnail_with_fsl_slicer(output_directory, nifti_filename, png_filename)
    nii_path = File.join(output_directory, nifti_filename)
    @path = File.join(output_directory, png_filename)
    Pathname.new(dataset.directory).all_dicoms do |dicom_files| 
      # First Create a Nifti File to read 
      @dataset.to_nifti!(output_directory, nifti_filename, {:input_directory => File.dirname(dicom_files.first)} )
    end
    
    
    
    # Then create the .png
    `slicer #{nii_path} -a #{@path}`
    
    raise(ScriptError, "Error creating thumbnail #{@path}") unless File.exist?(@path)
    
    return @path
  end
  
end
