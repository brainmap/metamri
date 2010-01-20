#!/usr/bin/env ruby

=begin rdoc
Builds Nifti files from Dicoms.
=end

TO3D_CMD = 'to3d'

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
    
    nifti_output_file = File.join(nifti_output_directory, nifti_filename)
    
    File.makedirs(nifti_output_directory) unless File.directory?(nifti_output_directory)
    raise(IOError, "Cannot write to #{nifti_output_directory}") unless File.writable?(nifti_output_directory)
        
    nifti_conversion_command = "#{TO3D_CMD} -session #{nifti_output_directory} -prefix #{nifti_filename} #{input_files}"

    return nifti_conversion_command, nifti_output_file
  end
end