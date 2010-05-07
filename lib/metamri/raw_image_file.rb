
require 'rubygems';
require 'yaml';
require 'sqlite3';

=begin rdoc
Implements a collection of metadata associated with a raw image file.  In
this case, by image we mean one single file.  For the case of Pfiles one file
corresponds to a complete 4D data set.  For dicoms one file corresponds to a single
2D slice, many of which are assembled later during reconstruction to create a
4D data set.  The motivation for this class is to provide access to the metadata
stored in image file headers so that they can be later reconstructed into nifti
data sets.
=end
class RawImageFile
  #:stopdoc:
  MIN_HDR_LENGTH = 400
  DICOM_HDR = "dicom_hdr"
  RDGEHDR = "rdgehdr"
  MONTHS = {
    :jan => "01", :feb => "02", :mar => "03", :apr => "04", :may => "05", 
    :jun => "06", :jul => "07", :aug => "08", :sep => "09", :oct => "10", 
    :nov => "11", :dec => "12" 
  }
  #:startdoc:

  # The file name that the instance represents.
  attr_reader :filename
  # Which header reading utility reads this file, currently 'rdgehdr' or 'dicom_hdr'.
  attr_reader :hdr_reader
  # File types are either 'dicom' or 'pfile'.
  attr_reader :file_type
  # The date on which this scan was acquired, this is a ruby DateTime object.
  attr_reader :timestamp
  # The scanner used to perform this scan, e.g. 'Andys3T'.
  attr_reader :source
  # An identifier unique to a 'visit', these are assigned by the scanner techs at scan time.
  attr_reader :rmr_number
  # A short string describing the acquisition sequence. These come from the scanner.
  # code and are used to initialise SeriesDescription objects to find related attributes.
  attr_reader :series_description
  # M or F.
  attr_reader :gender
  # Number of slices in the data set that includes this file, used by AFNI for reconstruction.
  attr_reader :num_slices
  # Given in millimeters.
  attr_reader :slice_thickness
  # Gap between slices in millimeters.
  attr_reader :slice_spacing
  # AKA Field of View, in millimeters.
  attr_reader :reconstruction_diameter
  # Voxels in x axis.
  attr_reader :acquisition_matrix_x
  # Voxels in y axis.
  attr_reader :acquisition_matrix_y
  # Time for each bold repetition, relevent for functional scans.
  attr_reader :rep_time
  # Number of bold reps in the complete functional task run.
  attr_reader :bold_reps
  # Import Warnings - Fields that could not be read.
  attr_reader :warnings

=begin rdoc
Creates a new instance of the class given a path to a valid image file.

Throws IOError if the file given is not found or if the available header reading
utilities cannot read the image header.  Also raises IOError if any of the
attributes cannot be found in the header.  Be aware that the filename used to
initialize your instance is used to set the "file" attribute.  If you need to
unzip a file to a temporary location, be sure to keep the same filename for the
temporary file.
=end
  def initialize(pathtofile)
    # raise an error if the file doesn't exist
    absfilepath = File.expand_path(pathtofile)
    raise(IOError, "File not found at #{absfilepath}.") if not File.exists?(absfilepath)
    @filename = File.basename(absfilepath)
    @warnings = []
    
    # try to read the header, raise an IOError if unsuccessful
    begin
      @hdr_data, @hdr_reader = read_header(absfilepath)
      #puts "@hdr_data: #{@hdr_data}; @hdr_reader: #{@hdr_reader}"
    rescue Exception => e
      raise(IOError, "Header not readable for file #{@filename}. #{e}")
    end
    
    # file type is based on file name but only if the header was read successfully
    @file_type = determine_file_type
    
    # try to import attributes from the header, raise an ioerror if any attributes
    # are not found
    begin
      import_hdr
    rescue ScriptError => e
      raise ScriptError, "Could not find required DICOM Header Meta Element: #{e}"
    rescue Exception => e
      raise IOError, "Header import failed for file #{@filename}.  #{e}"
    end
    
    # deallocate the header data to save memory space.
    @hdr_data = nil
  end
  

=begin rdoc
Predicate method that tells whether or not the file is actually an image.  This
judgement is based on whether one of the available header reading utilities can
actually read the header information.
=end
  def image?
    return ( @hdr_reader == RDGEHDR or @hdr_reader == DICOM_HDR )
  end
  
  
=begin rdoc
Predicate simply returns true if "pfile" is stored in the @img_type instance variable.
=end
  def pfile?
    return @file_type == "pfile"
  end


=begin rdoc
Predicate simply returns true if "dicom" is stored in the img_type instance variable.
=end
  def dicom?
    return @file_type == "dicom"
  end
  
  
=begin rdoc
Returns a yaml string based on a subset of the attributes.  Specifically,
the @hdr_data is not included.  This is used to generate .yaml files that are 
placed in image directories for later scanning by YamlScanner.
=end
  def to_yaml
    yamlhash = {}
    instance_variables.each do |var|
      yamlhash[var[1..-1]] = instance_variable_get(var) if (var != "@hdr_data")
    end
    return yamlhash.to_yaml
  end
 
   
=begin rdoc
Returns the internal, parsed data fields in an array. This is used when scanning
dicom slices, to compare each dicom slice in a folder and make sure they all hold the
same data.
=end
  def to_array
    return [@filename,
    @timestamp,
    @source,
    @rmr_number,
    @series_description,
    @gender,
    @slice_thickness,
    @slice_spacing,
    @reconstruction_diameter, 
    @acquisition_matrix_x,
    @acquisition_matrix_y]
  end
  
=begin rdoc
Returns an SQL statement to insert this image into the raw_images table of a 
compatible database (sqlite3).  This is intended for inserting into the rails
backend database.
=end
  def db_insert(image_dataset_id)
    "INSERT INTO raw_image_files
    (filename, header_reader, file_type, timestamp, source, rmr_number, series_description, 
    gender, num_slices, slice_thickness, slice_spacing, reconstruction_diameter, 
    acquisition_matrix_x, acquisition_matrix_y, rep_time, bold_reps, created_at, updated_at, image_dataset_id)
    VALUES ('#{@filename}', '#{@hdr_reader}', '#{@file_type}', '#{@timestamp.to_s}', '#{@source}', '#{@rmr_number}', 
    '#{@series_description}', '#{@gender}', #{@num_slices}, #{@slice_thickness}, #{@slice_spacing}, 
    #{@reconstruction_diameter}, #{@acquisition_matrix_x}, #{@acquisition_matrix_y}, #{@rep_time}, 
    #{@bold_reps}, '#{DateTime.now}', '#{DateTime.now}', #{image_dataset_id})"
  end

=begin rdoc
Returns an SQL statement to select this image file row from the raw_image_files table
of a compatible database.
=end
  def db_fetch
    "SELECT *" + from_table_where + sql_match_conditions
  end
  
=begin rdoc
Returns and SQL statement to remove this image file from the raw_image_files table
of a compatible database.
=end
  def db_remove
    "DELETE" + from_table_where + sql_match_conditions
  end
  
  
=begin rdoc
Uses the db_insert method to actually perform the database insert using the 
specified database file.
=end  
  def db_insert!( db_file )
    db = SQLite3::Database.new( db_file )
    db.transaction do |database|
      if not database.execute( db_fetch ).empty?
        raise(IndexError, "Entry exists for #{filename}, #{@rmr_number}, #{@timestamp.to_s}... Skipping.")
      end
      database.execute( db_insert )
    end
    db.close
  end

=begin rdoc
Removes this instance from the raw_image_files table of the specified database.
=end
  def db_remove!( db_file )
    db = SQLite3::Database.new( db_file )
    db.execute( db_remove )
    db.close
  end
  
=begin rdoc
Finds the row in the raw_image_files table of the given db file that matches this object.
ORM is based on combination of rmr_number, timestamp, and filename.  The row is returned 
as an array of values (see 'sqlite3' gem docs).
=end
  def db_fetch!( db_file )
    db = SQLite3::Database.new( db_file )
    db_row = db.execute( db_fetch )
    db.close
    return db_row
  end
  



private



  def from_table_where
    " FROM raw_image_files WHERE "
  end

  def sql_match_conditions
    "rmr_number = '#{@rmr_number}' AND timestamp = '#{@timestamp.to_s}' AND filename = '#{@filename}'"
  end

=begin rdoc
Reads the file header using one of the available header reading utilities. 
Returns both the header data as a one big string, and the name of the utility 
used to read it.

Note: The rdgehdr is a binary file; the correct version for your architecture must be installed in the path.
=end
  def read_header(absfilepath)
    header = `#{DICOM_HDR} '#{absfilepath}' 2> /dev/null`
    #header = `#{DICOM_HDR} #{absfilepath}`
    if ( header.index("ERROR") == nil and 
         header.chomp != "" and 
         header.length > MIN_HDR_LENGTH )
      return [ header, DICOM_HDR ]
    end
    header = `#{RDGEHDR} '#{absfilepath}' 2> /dev/null`
    #header = `#{RDGEHDR} #{absfilepath}`
    if ( header.chomp != "" and
         header.length > MIN_HDR_LENGTH )
      return [ header, RDGEHDR ]
    end
    return [ nil, nil ]
  end


=begin rdoc
Returns a string that indicates the file type.  This is difficult because dicom
files have no consistent naming conventions/suffixes.  Here we chose to call a
file a "pfile" if it is an image and the file name is of the form P*.7
All other images are called "dicom".
=end
  def determine_file_type
    return "pfile" if image? and (@filename =~ /^P.....\.7/) != nil
    return "dicom" if image? and (@filename =~ /^P.....\.7/) == nil
    return nil
  end


=begin rdoc
Parses the header data and extracts a collection of instance variables.  If 
@hdr_data and @hdr_reader are not already availables, this function does nothing.
=end
  def import_hdr
    raise(IndexError, "No Header Data Available.") if @hdr_data == nil
    dicom_hdr_import if (@hdr_reader == "dicom_hdr")
    rdgehdr_import if (@hdr_reader == "rdgehdr")
  end


=begin rdoc
Extracts a collection of metadata from @hdr_data retrieved using the dicom_hdr
utility.  
=end
  def dicom_hdr_import
    meta_matchers = {}
    meta_matchers[:rmr_number] = { 
      :type => :string, 
      :pat => /[ID Accession Number|ID Study Description]\/\/(RMR.*)\n/i, 
      :required => true 
    }
    meta_matchers[:slice_thickness] = { 
      :type => :float, 
      :pat => /ACQ SLICE THICKNESS\/\/(.*)\n/i,
      :required => false
    }
    meta_matchers[:slice_spacing] = {
      :type => :float,
      :pat => /ACQ SPACING BETWEEN SLICES\/\/(.*)\n/i,
      :required => false
    }
    meta_matchers[:source] = {
      :type => :string,
      :pat => /ID INSTITUTION NAME\/\/(.*)\n/i,
      :required => true
    } 
    meta_matchers[:series_description] = {
      :type => :string,
      :pat => /ID SERIES DESCRIPTION\/\/(.*)\n/i,
      :required => true 
    }
    meta_matchers[:gender] = {
      :type => :string,
      :pat => /PAT PATIENT SEX\/\/(.)/i,
      :required => false
    }
    meta_matchers[:reconstruction_diameter] = {
      :type => :int,
      :pat => /ACQ RECONSTRUCTION DIAMETER\/\/([0-9]+)/i,
      :required => false
    }
    meta_matchers[:acquisition_matrix_x] = {
      :type => :int,
      :pat => /IMG Rows\/\/ ([0-9]+)/i,
      :required => false
    }
    meta_matchers[:acquisition_matrix_y] = {
      :type => :int,
      :pat => /IMG Columns\/\/ ([0-9]+)/i,
      :required => false
    }
    meta_matchers[:num_slices] = {
      :type => :int,
      :pat => /REL Images in Acquisition\/\/([0-9]+)/i,
      :required => false
    }
    meta_matchers[:bold_reps] = {
      :type => :int,
      :pat => /REL Number of Temporal Positions\/\/([0-9]+)/i,
      :required => false
    }
    meta_matchers[:rep_time] = {
      :type => :float,
      :pat => /ACQ Repetition Time\/\/(.*)\n/i,
      :required => false
    }
    meta_matchers[:date] = {
      :type => :datetime,
      :pat => /ID STUDY DATE\/\/(.*)\n/i #,
      # :required => false
  }
    meta_matchers[:time] = {
      :type => :datetime,
      :pat => /ID Series Time\/\/(.*)\n/i #,
      # :required => false
    }
    
    meta_matchers.each_pair do |name, tag_hash|
      begin
        next if tag_hash[:type] == :datetime
        tag_hash[:pat] =~ @hdr_data
        raise ScriptError, "No match found for #{name}" if ($1).nil? 
        value = case tag_hash[:type]
          when :string then ($1).strip.chomp
          when :float then ($1).strip.chomp.to_f
          when :int then ($1).to_i
        end
        self.instance_variable_set("@#{name}", value)
      rescue ScriptError => e
        if tag_hash[:required]
          raise ScriptError, "#{name}"
        else
          @warnings << "Tag #{name} could not be found."
        end
      end
    end

    # Set Timestamp separately because it requires both Date and Time to be extracted.
    meta_matchers[:date][:pat] =~ @hdr_data
    date = $1
    meta_matchers[:time][:pat] =~ @hdr_data
    time = $1
    @timestamp = DateTime.parse(date + time)
    
  end
  

=begin rdoc
Extracts a collection of metadata from @hdr_data retrieved using the rdgehdr
utility. 
=end
  def rdgehdr_import
    source_pat =               /hospital [Nn]ame: ([[:graph:]\t ]+)/i
    num_slices_pat =           /Number of slices in this scan group: ([0-9]+)/i
    slice_thickness_pat =      /slice thickness \(mm\): ([[:graph:]]+)/i
    slice_spacing_pat =        /spacing between scans \(mm\??\): ([[:graph:]]+)/i
    date_pat =                 /actual image date\/time stamp: (.*)\n/i
    gender_pat =               /Patient Sex: (1|2)/i
    acquisition_matrix_x_pat = /Image matrix size \- X: ([0-9]+)/i
    acquisition_matrix_y_pat = /Image matrix size \- Y: ([0-9]+)/i
    series_description_pat =   /Series Description: ([[:graph:] \t]+)/i
    recon_diam_pat =           /Display field of view \- X \(mm\): ([0-9]+)/i
    rmr_number_pat =           /Patient ID for this exam: ([[:graph:]]+)/i
    bold_reps_pat =            /Number of excitations: ([0-9]+)/i
    rep_time_pat =             /Pulse repetition time \(usec\): ([0-9]+)/i

    rmr_number_pat =~ @hdr_data
    @rmr_number = ($1).nil? ? "rmr not found" : ($1).strip.chomp
    
    source_pat =~ @hdr_data
    @source = ($1).nil? ? "source not found" : ($1).strip.chomp
    
    num_slices_pat =~ @hdr_data
    @num_slices = ($1).to_i
    
    slice_thickness_pat =~ @hdr_data
    @slice_thickness = ($1).to_f
    
    slice_spacing_pat =~ @hdr_data
    @slice_spacing = ($1).to_f
    
    date_pat =~ @hdr_data
    @timestamp = DateTime.parse($1)
    
    gender_pat =~ @hdr_data
    @gender = $1 == 1 ? "M" : "F"
    
    acquisition_matrix_x_pat =~ @hdr_data
    @acquisition_matrix_x = ($1).to_i
    acquisition_matrix_y_pat =~ @hdr_data
    @acquisition_matrix_y = ($1).to_i
    
    series_description_pat =~ @hdr_data
    @series_description = ($1).strip.chomp
    
    recon_diam_pat =~ @hdr_data
    @reconstruction_diameter = ($1).to_i
    
    bold_reps_pat =~ @hdr_data
    @bold_reps = ($1).to_i
    
    rep_time_pat =~ @hdr_data
    @rep_time = ($1).to_f / 1000000
  end
 
end