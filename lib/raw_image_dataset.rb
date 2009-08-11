
require 'rubygems'
require 'sqlite3'

=begin rdoc
A #Dataset defines a single 3D or 4D image, i.e. either a volume or a time series
of volumes.  This encapsulation will provide easy manipulation of groups of raw
image files including basic reconstruction.
=end
class RawImageDataset

  # The directory that contains all the raw images and related files that make up
  # this data set.
  attr_reader :directory
  # An array of #RawImageFile objects that compose the complete data set.
  attr_reader :raw_image_files
  # From the first raw image file in the dataset
  attr_reader :series_description
  # From the first raw image file in the dataset
  attr_reader :rmr_number
  # From the first raw image file in the dataset
  attr_reader :timestamp
  # A key string unique to a dataset composed of the rmr number and the timestamp.
  attr_reader :dataset_key
  # the file scanned
  attr_reader :scanned_file
  # the scanner source
  attr_reader :scanner_source
  

=begin rdoc
  * dir: The directory containing the files.
  * files: An array of #RawImageFile objects that compose the complete data set.
  
  Initialization raises errors in several cases:
  * directory doesn't exist => IOError
  * any of the raw image files is not actually a RawImageFile => IndexError
  * series description, rmr number, or timestamp cannot be extracted from the first RawImageFile => IndexError
=end
  def initialize(directory, raw_image_files)
    @directory = File.expand_path(directory)
    raise(IOError, "#{@directory} not found.") if not File.directory?(@directory)
    raise(IOError, "No raw image files supplied.") if (raw_image_files.nil? or raw_image_files.empty?)
    raw_image_files.each do |im|
      raise(IndexError, im.to_s + " is not a RawImageFile") if im.class.to_s != "RawImageFile"
    end
    @raw_image_files = raw_image_files
    @series_description = @raw_image_files.first.series_description
    raise(IndexError, "No series description found") if @series_description.nil?
    @rmr_number = @raw_image_files.first.rmr_number
    raise(IndexError, "No rmr found") if @rmr_number.nil?
    @timestamp = get_earliest_timestamp
    raise(IndexError, "No timestamp found") if @timestamp.nil?
    @dataset_key = @rmr_number + "::" + @timestamp.to_s
    @scanned_file = @raw_image_files.first.filename
    raise(IndexError, "No scanned file found") if @scanned_file.nil?
    @scanner_source = @raw_image_files.first.source
    raise(IndexError, "No scanner source found") if @scanner_source.nil?
  end

=begin rdoc
Generates an SQL insert statement for this dataset that can be used to populate
the Johnson Lab rails TransferScans application database backend.  The motivation
for this is that many dataset inserts can be collected into one db transaction
at the visit level, or even higher when doing a whole file system scan.
=end
  def db_insert(visit_id)
    "INSERT INTO image_datasets
    (rmr, series_description, path, timestamp, created_at, updated_at, visit_id, 
    glob, rep_time, bold_reps, slices_per_volume, scanned_file)
    VALUES ('#{@rmr_number}', '#{@series_description}', '#{@directory}', '#{@timestamp.to_s}', '#{DateTime.now}', 
    '#{DateTime.now}', '#{visit_id}', '#{self.glob}', '#{@raw_image_files.first.rep_time}', 
    '#{@raw_image_files.first.bold_reps}', '#{@raw_image_files.first.num_slices}', '#{@scanned_file}')"
  end
  
  def db_update(dataset_id)
    "UPDATE image_datasets SET
     rmr = '#{@rmr_number}',
     series_description = '#{@series_description}',
     path = '#{@directory}',
     timestamp = '#{@timestamp.to_s}',
     updated_at = '#{DateTime.now.to_s}',
     glob = '#{self.glob}',
     rep_time = '#{@raw_image_files.first.rep_time}',
     bold_reps = '#{@raw_image_files.first.bold_reps}',
     slices_per_volume = '#{@raw_image_files.first.num_slices}',
     scanned_file = '#{@scanned_file}'
     WHERE id = '#{dataset_id}'"
  end
  
  def db_fetch
    "SELECT * FROM image_datasets 
     WHERE rmr = '#{@rmr_number}' 
     AND path = '#{@directory}' 
     AND timestamp LIKE '#{@timestamp.to_s.split(/\+|Z/).first}%'"
  end
  
  def attributes_for_active_record
    { :rmr => @rmr_number,
      :series_description => @series_description,
      :path => @directory,
      :timestamp => @timestamp.to_s,
      :glob => glob,
      :rep_time => @raw_image_files.first.rep_time,
      :bold_reps => @raw_image_files.first.bold_reps,
      :slices_per_volume => @raw_image_files.first.num_slices,
      :scanned_file => @scanned_file }
  end
   


=begin rdoc
Returns a globbing wildcard that is used by to3D to gather files for
reconstruction.  If no compatible glob is found for the data set, nil is returned.
This is always the case for pfiles. For example if the first file in a data set is I.001, then:
<tt>dataset.glob</tt>
<tt>=> "I.*"</tt>
including the quotes, which are necessary becuase some data sets (functional dicoms)
have more component files than shell commands can handle.
=end
  def glob
    case @raw_image_files.first.filename
    when /^E.*dcm$/
      return 'E*.dcm'
    when /\.dcm$/
      return '*.dcm'
    when /^I\./
      return 'I.*'
    when /^I/
      return 'I*.dcm'
    when /\.0/
      return '*.0*'
    else
      return nil
    end
  end
  
private
  
  # Gets the earliest timestamp among the raw image files in this dataset.
  def get_earliest_timestamp
    @timestamp = (@raw_image_files.sort_by { |i| i.timestamp }).first.timestamp
  end


end
#### END OF CLASS ####