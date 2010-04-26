require 'tmpdir'

# This class is a ruby object encapsulating a .jpg Thumbnail of a Dataset
class RawImageDatasetThumbnail

  attr_reader :dataset, :path

  def initialize(dataset)
    @dataset = dataset
  end
  
  def create_thumbnail(output = nil)
    if output
      if File.directory?(output)
        output_directory = output
      else
        output_directory = File.dirname(output)
        png_filename = File.basename(output)
      end
    else
      output_directory = Dir.mktmpdir
    end
    name = @dataset.series_description.escape_filename
    png_filename ||= name + '.png'
    
    create_thumbnail_with_fsl_slicer(output_directory, name, png_filename)
  end
  
  private
  
  def create_thumbnail_with_fsl_slicer(output_directory, name, png_filename)
    # First Create a Nifti File to read 
    nifti_filename =  name + '.nii'
    
    @dataset.to_nifti!(output_directory, nifti_filename, {:input_directory => @dataset.directory} )
    nii_path = File.join(output_directory, nifti_filename)
    @path = File.join(output_directory, png_filename)
    `slicer #{nii_path} -a #{@path}`
    
    return @path
  end
  
end
