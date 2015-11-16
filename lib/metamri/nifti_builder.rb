# encoding: utf-8
# Builds Nifti files from Dicoms.
module UnknownImageDataset
  # Always set AFNI GE DICOM Fix to "No" before conversion with to3d.
  ENV['AFNI_SLICE_SPACING_IS_GAP'] = "NO"

  
  def dataset_to_nifti(nifti_output_directory, nifti_filename, input_options = {} )
    if input_options.has_key?(:dicom_files)
      input_files = input_options[:dicom_files].each {|file| file.to_s }.join(' ')
    elsif input_options.has_key?(:input_directory)
      input_files = "#{input_options[:input_directory]}/'#{glob}'"
    else input_files = "#{Dir.tmpdir}/'#{glob}'"
    end

    if @raw_image_files.first.rep_time && @raw_image_files.first.bold_reps && @raw_image_files.first.num_slices && !input_options[:no_timing_options]
      slice_order = "altplus"
      functional_args = "-time:zt #{@raw_image_files.first.num_slices} #{@raw_image_files.first.bold_reps} #{@raw_image_files.first.rep_time} #{slice_order}"
    end
    
    
    nifti_output_file = File.join(nifti_output_directory, nifti_filename)
    
    FileUtils.makedirs(nifti_output_directory) unless File.directory?(nifti_output_directory)
    raise(IOError, "Cannot write to #{nifti_output_directory}") unless File.writable?(nifti_output_directory)
        
    nifti_conversion_command = "to3d -session #{nifti_output_directory} -prefix #{[nifti_filename, functional_args, input_files].compact.join(' ')}"

    return nifti_conversion_command, nifti_output_file
  end
end

module DTIDataset
  def dataset_to_nifti(nifti_output_directory, nifti_filename, input_options = {} )
    
  end
end