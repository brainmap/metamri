require 'pp'
require 'rubygems';
require 'yaml';
# require 'sqlite3';
require 'dicom'


# Implements a collection of metadata associated with a raw image file.  In
# this case, by image we mean one single file.  For the case of Pfiles one file
# corresponds to a complete 4D data set.  For dicoms one file corresponds to a single
# 2D slice, many of which are assembled later during reconstruction to create a
# 4D data set.  The motivation for this class is to provide access to the metadata
# stored in image file headers so that they can be later reconstructed into nifti
# data sets.
# 
# Primarily used to instantiate a #RawImageDataset
class RawImageFile
  #:stopdoc:
  MIN_HDR_LENGTH = 400
  DICOM_HDR = "dicom_hdr"
  RDGEHDR = "rdgehdr"
  PRINTRAW = "printraw"
  RUBYDICOM_HDR = "rubydicom"
  VALID_HEADERS = [DICOM_HDR, PRINTRAW, RDGEHDR, RUBYDICOM_HDR]
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
  # An identifier unique to a Study Session - AKA Exam Number
  attr_reader :exam_number
  # A short string describing the acquisition sequence. These come from the scanner.
  # code and are used to initialise SeriesDescription objects to find related attributes.
  attr_reader :series_description
  # A short string describing the study sequence. These come from the scanner.
  attr_reader :study_description
  # A short string describing the study protocol. These come from the scanner.
  attr_reader :protocol_name
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
  # Serialized RubyDicomHeader Object (for DICOMs only)
  attr_reader :dicom_header
  # Hash of all DICOM Tags including their Names and Values (See #dicom_taghash for more information on the structure)
  attr_reader :dicom_taghash
  # DICOM SOP Instance UID (from the scanned file)
  attr_reader :dicom_image_uid
  # DICOM Series UID
  attr_reader :dicom_series_uid
  # DICOM Study UID
  attr_reader :dicom_study_uid
  # Scan Tech Initials
  attr_reader :operator_name
  # Patient "Name", usually StudyID or ENUM
  attr_reader :patient_name
  
  # Creates a new instance of the class given a path to a valid image file.
  # 
  # Throws IOError if the file given is not found or if the available header reading
  # utilities cannot read the image header.  Also raises IOError if any of the
  # attributes cannot be found in the header.  Be aware that the filename used to
  # initialize your instance is used to set the "file" attribute.  If you need to
  # unzip a file to a temporary location, be sure to keep the same filename for the
  # temporary file.
  def initialize(pathtofile)
    # raise an error if the file doesn't exist
    absfilepath = File.expand_path(pathtofile)
    raise(IOError, "File not found at #{absfilepath}.") if not File.exists?(absfilepath)
    @filename = File.basename(absfilepath)
    @warnings = []
    
    # try to read the header, raise an IOError if unsuccessful
    begin
      @hdr_data, @hdr_reader = read_header(absfilepath)
    rescue Exception => e
      raise(IOError, "Header not readable for file #{@filename} using #{@current_hdr_reader ? @current_hdr_reader : "unknown header reader."}. #{e}")
    end
    
    # file type is based on file name but only if the header was read successfully
    @file_type = determine_file_type
    
    # try to import attributes from the header, raise an ScriptError or NoMethodError 
    # if any required attributes are not found
    begin
      import_hdr
    rescue ScriptError, NoMethodError => e
      # puts e.backtrace
      raise e, "Could not find required DICOM Header Meta Element: #{e}"
    rescue StandardError => e
      raise e, "Header import failed for file #{@filename}.  #{e}"
    end
    
    # deallocate the header data to save memory space.
    @hdr_data = nil
  end
  


  # Predicate method that tells whether or not the file is actually an image.  This
  # judgement is based on whether one of the available header reading utilities can
  # actually read the header information.
  def image?
    return ( VALID_HEADERS.include? @hdr_reader )
  end
  
  

  # Predicate simply returns true if "pfile" is stored in the @img_type instance variable.
  def pfile?
    return @file_type == "pfile"
  end


  # Predicate simply returns true if "dicom" is stored in the img_type instance variable.
  def dicom?
    return @file_type == "dicom"
  end
  
  def geifile?
    return @file_type == "geifile"
  end
  
  
  # Returns a yaml string based on a subset of the attributes.  Specifically,
  # the @hdr_data is not included.  This is used to generate .yaml files that are 
  # placed in image directories for later scanning by YamlScanner.
  def to_yaml
    yamlhash = {}
    instance_variables.each do |var|
      yamlhash[var[1..-1]] = instance_variable_get(var) if (var != "@hdr_data")
    end
    return yamlhash.to_yaml
  end
 
   
  # Returns the internal, parsed data fields in an array. This is used when scanning
  # dicom slices, to compare each dicom slice in a folder and make sure they all hold the
  # same data.
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
  
  # Returns an SQL statement to insert this image into the raw_images table of a 
  # compatible database (sqlite3).  This is intended for inserting into the rails
  # backend database.
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

  # Returns an SQL statement to select this image file row from the raw_image_files table
  # of a compatible database.
  def db_fetch
    "SELECT *" + from_table_where + sql_match_conditions
  end
  
  # Returns and SQL statement to remove this image file from the raw_image_files table
  # of a compatible database.
  def db_remove
    "DELETE" + from_table_where + sql_match_conditions
  end
  
  
  # Uses the db_insert method to actually perform the database insert using the 
  # specified database file.
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

  # Removes this instance from the raw_image_files table of the specified database.
  def db_remove!( db_file )
    db = SQLite3::Database.new( db_file )
    db.execute( db_remove )
    db.close
  end
  
  # Finds the row in the raw_image_files table of the given db file that matches this object.
  # ORM is based on combination of rmr_number, timestamp, and filename.  The row is returned 
  # as an array of values (see 'sqlite3' gem docs).
  def db_fetch!( db_file )
    db = SQLite3::Database.new( db_file )
    db_row = db.execute( db_fetch )
    db.close
    return db_row
  end
  
  # The series ID (dicom_series_uid [dicom] or series_uid [pfile/ifile])
  # This is unique for DICOM datasets, but not for PFiles
  def series_uid
    @dicom_series_uid || @series_uid
  end
  
  # The UID unique to the raw image file scanned
  def image_uid
    @dicom_image_uid || @image_uid
  end

private



  def from_table_where
    " FROM raw_image_files WHERE "
  end

  def sql_match_conditions
    "rmr_number = '#{@rmr_number}' AND timestamp = '#{@timestamp.to_s}' AND filename = '#{@filename}'"
  end

  # Reads the file header using one of the available header reading utilities. 
  # Returns both the header data as either a RubyDicom object or one big string, and the name of the utility 
  # used to read it.
  # 
  # Note: The rdgehdr is a binary file; the correct version for your architecture must be installed in the path.
  def read_header(absfilepath)

    case File.basename(absfilepath)
    when /^P.{5}\.7$|^I\..{3}/
            # Try reading Pfiles or Genesis I-Files with GE's printraw
      @current_hdr_reader = PRINTRAW
      header = `#{PRINTRAW} '#{absfilepath}' 2> /dev/null`
      #header = `#{RDGEHDR} #{absfilepath}`
      if ( header.chomp != "" and
           header.length > MIN_HDR_LENGTH )
        @current_hdr_reader = nil
        return [ header, PRINTRAW ]
      end
      # Try reading Pfiles or Genesis I-Files with GE's rdgehdr -- rdgehdr newer version needs macos 10.8, adrcdev2 = 10.7.5 - 
      # works on old headers, not on new header format
      ###@current_hdr_reader = RDGEHDR
      ###header = `#{RDGEHDR} '#{absfilepath}' 2> /dev/null`
      #header = `#{RDGEHDR} #{absfilepath}`
      ###if ( header.chomp != "" and
      ###     header.length > MIN_HDR_LENGTH )
      ###  @current_hdr_reader = nil
      ###  return [ header, RDGEHDR ]
      ### end
    else
      # Try reading with RubyDICOM
      @current_hdr_reader = RUBYDICOM_HDR
      header = DICOM::DObject.new(absfilepath)
      if defined? header.read_success && header.read_success
        @current_hdr_reader = nil
        return [header, RUBYDICOM_HDR] 
      end
      
      # Try reading with AFNI's dicom_hdr
      @current_hdr_reader = DICOM_HDR
      header = `#{DICOM_HDR} '#{absfilepath}' 2> /dev/null`
      #header = `#{DICOM_HDR} #{absfilepath}`
      if ( header.index("ERROR") == nil and 
           header.chomp != "" and 
           header.length > MIN_HDR_LENGTH )
        @current_hdr_reader = nil
        return [ header, DICOM_HDR ]
      end
    end

    @current_hdr_reader = nil
    return [ nil, nil ]
  end


  # Returns a string that indicates the file type.  This is difficult because dicom
  # files have no consistent naming conventions/suffixes.  Here we chose to call a
  # file a "pfile" if it is an image and the file name is of the form P*.7
  # All other images are called "dicom".
  def determine_file_type
    return "pfile"    if image? and (@filename =~ /^P.....\.7/) != nil
    return "geifile"  if image? and (@filename =~ /^I\.\d*/) != nil
    return "dicom"    if image? and (@filename =~ /^P.....\.7/) == nil
    return nil
  end


  # Parses the header data and extracts a collection of instance variables.  If 
  # @hdr_data and @hdr_reader are not already available, this function does nothing.
  def import_hdr
    raise(IndexError, "No Header Data Available.") if @hdr_data == nil
    case @hdr_reader
      when "rubydicom" then rubydicom_hdr_import
      when "dicom_hdr" then dicom_hdr_import
      when "printraw" then printraw_import
      when "rdgehdr" then rdgehdr_import
    end
  end


  # Extract a collection of metadata from @hdr_data retrieved using RubyDicom
  # 
  #   Here are some example DICOM Tags and Values
  #   0008,0022 Acquisition Date                     DA      8 20101103
  #   0008,0030 Study Time                           TM      6 101538
  #   0008,0080 Institution Name                     LO      4 Institution
  #   0008,1010 Station Name                         SH      8 Station
  #   0008,0018 SOP Instance UID                            12 1.2.840.113619.2.155.3596.6906438.17031.1121881958.942
  #   0008,1030 Study Description                    LO     12 PILOT Study
  #   0008,103E Series Description                   LO     12 3pl loc FGRE
  #   0008,1070 Operators' Name                      PN      2 SP
  #   0008,1090 Manufacturer's Model Name            LO     16 DISCOVERY MR750
  #   0010,0010 Patient's Name                       PN     12 mosPilot
  #   0010,0020 Patient ID                           LO     12 RMREKKPilot
  #   0010,0040 Patient's Sex                        CS      2 F
  #   0010,1010 Patient's Age                        AS      4 027Y
  #   0010,1030 Patient's Weight                     DS      4 49.9
  #   0018,0023 MR Acquisition Type                  CS      2 2D
  #   0018,0050 Slice Thickness                      DS      2 10
  #   0018,0080 Repetition Time                      DS      6 5.032
  #   0018,0081 Echo Time                            DS      6 1.396
  #   0018,0082 Inversion Time                       DS      2 0
  #   0018,0083 Number of Averages                   DS      2 1
  #   0018,0087 Magnetic Field Strength              DS      2 3
  #   0018,0088 Spacing Between Slices               DS      4 12.5
  #   0018,0091 Echo Train Length                    IS      2 1
  #   0018,0093 Percent Sampling                     DS      4 100
  #   0018,0094 Percent Phase Field of View          DS      4 100
  #   0018,0095 Pixel Bandwidth                      DS      8 244.141
  #   0018,1000 Device Serial Number                 LO     16 0000006080000
  #   0018,1020 Software Version(s)                  LO     42 21\LX\MR Software release:20..
  #   0018,1030 Protocol Name                        LO     22 MOSAIC Pilot 02Nov2010
  #   0018,1100 Reconstruction Diameter              DS      4 240
  #   0018,1250 Receive Coil Name                    SH      8 8HRBRAIN
  #   0018,1310 Acquisition Matrix                   US      8 0\256\128\0
  #   0018,1312 In-plane Phase Encoding Direction    CS      4 ROW
  #   0018,1314 Flip Angle                           DS      2 30
  #   0018,1315 Variable Flip Angle Flag             CS      2 N
  #   0018,1316 SAR                                  DS      8 0.498088
  #   0020,000D Study Instance UID                   UI     52 1.2.840.113619.6.260.4.88937..
  #   0020,000E Series Instance UID                  UI     54 1.2.840.113619.2.260.6945.23..
  #   0020,0010 Study ID                             SH      4 1260
  #   0020,0011 Series Number                        IS      2 1
  #   0020,0012 Acquisition Number                   IS      2 1
  #   0020,0013 Instance Number                      IS      2 1
  #   0020,0032 Image Position (Patient)             DS     22 -119.531\-159.531\-25
  #   0020,1002 Images in Acquisition                IS      2 15
  #   0028,0010 Rows                                 US      2 256
  #   0028,0011 Columns                              US      2 256
  #   0028,0030 Pixel Spacing                        DS     14 0.9375\0.9375
  def rubydicom_hdr_import
    dicom_tag_attributes = {
      :source => "0008,0080",
      :series_description => "0008,103E",
      :study_description => "0008,1030",
      :operator_name => "0008,1070",
      :patient_name => "0010,0010",
      :rmr_number => "0010,0020",
      :gender => "0010,0040",
      :slice_thickness => "0018,0050",
      :reconstruction_diameter => "0018,1100",
      :rep_time => "0018,0080",
      :pixel_spacing => "0028,0030",
      :flip_angle => "0018,1314",
      :field_strength => "0018,0087",
      :slice_spacing => "0018,0088",
      :software_version => "0018,1020",
      :protocol_name => "0018,1030",
      :bold_reps => "0020,0105",
      :dicom_image_uid => "0008,0018",    # Each DICOM Image (i.e. raw image file) has a unique SOP Instance UID
      :dicom_series_uid => "0020,000E",   # Series UID (shared by all dicoms in the same series)
      :dicom_study_uid => "0020,000D",
      :exam_number => "0020,0010",
      :num_slices => "0020,1002",
      :acquisition_matrix_x => "0028,0010",
      :acquisition_matrix_y => "0028,0011"
    }

    
    dicom_tag_attributes.each_pair do |name, tag|
      begin
        # next if tag_hash[:type] == :datetime
        value = @hdr_data[tag].value if @hdr_data[tag]
        raise ScriptError, "No match found for #{name}" unless value
        instance_variable_set("@#{name.to_s}", value)
      rescue ScriptError => e
        @warnings << "Tag #{name} could not be found."
      end
    end
    
    @timestamp = DateTime.parse(@hdr_data["0008,0022"].value + @hdr_data["0008,0030"].value)
    @dicom_taghash = create_dicom_taghash(@hdr_data)
    # @dicom_header = remove_long_dicom_elements(@hdr_data)

  end
  
  # # Remove long data elements from a rubydicom header.  This essentially strips 
  # # lengthy image data.
  # def remove_long_dicom_elements(header)
  #   raise ScriptError, "A DICOM::DObject instance is required" unless header.kind_of? DICOM::DObject
  #   h = header.dup
  #   h.children.select { |element| element.length > 100 }.each do |e|
  #     h.remove(e.tag)
  #     # puts "Removing #{e.tag}..."
  #   end
  #   return h
  # end
  
  # Create a super-lightweight representation of the DICOM header as a hash, where
  # the tags are they keys and name and value are stored as an attribute hash in value.
  # 
  # Creates a hash like:
  #  {"0018,0095"=>{:value=>"244.141", :name=>"Pixel Bandwidth"},
  #   "0008,1030"=>{:value=>"MOSAIC PILOT", :name=>"Study Description"} }
  # 
  # When serialized with yaml, this looks like:
  # 
  #  0018,0095: 
  #    :value: "244.141"
  #    :name: Pixel Bandwidth
  #   
  #  0008,1030: 
  #    :value: MOSAIC PILOT
  #    :name: Study Description
  # 
  # To filter and search, you can do something like:
  # tag_hash.each_pair {|tag, attributes| puts tag, attributes[:value] if attributes[:name] =~ /Description/i }
  def create_dicom_taghash(header)
    raise ScriptError, "A DICOM::DObject instance is required" unless header.kind_of? DICOM::DObject
    h = Hash.new
    header.children.each do |element|
      h[element.tag] = {:value => element.instance_variable_get(:@value), :name => element.name}
    end
    return h
  end

  # Extracts a collection of metadata from @hdr_data retrieved using the dicom_hdr
  # utility.  
  def dicom_hdr_import
    dicom_tag_templates = {}
    dicom_tag_templates[:rmr_number] = { 
      :type => :string, 
      :pat => /[ID Accession Number|ID Study Description]\/\/(RMR.*)\n/i, 
      :required => true 
    }
    dicom_tag_templates[:exam_number] = {
      :type => :string,
      :pat => /STUDY ID\/\/([0-9]+)/i,
      :required => true 
    }
    dicom_tag_templates[:slice_thickness] = { 
      :type => :float, 
      :pat => /ACQ SLICE THICKNESS\/\/(.*)\n/i,
      :required => false
    }
    dicom_tag_templates[:slice_spacing] = {
      :type => :float,
      :pat => /ACQ SPACING BETWEEN SLICES\/\/(.*)\n/i,
      :required => false
    }
    dicom_tag_templates[:source] = {
      :type => :string,
      :pat => /ID INSTITUTION NAME\/\/(.*)\n/i,
      :required => true
    } 
    dicom_tag_templates[:series_description] = {
      :type => :string,
      :pat => /ID SERIES DESCRIPTION\/\/(.*)\n/i,
      :required => true 
    }
    dicom_tag_templates[:gender] = {
      :type => :string,
      :pat => /PAT PATIENT SEX\/\/(.)/i,
      :required => false
    }
    dicom_tag_templates[:reconstruction_diameter] = {
      :type => :int,
      :pat => /ACQ RECONSTRUCTION DIAMETER\/\/([0-9]+)/i,
      :required => false
    }
    dicom_tag_templates[:acquisition_matrix_x] = {
      :type => :int,
      :pat => /IMG Rows\/\/ ([0-9]+)/i,
      :required => false
    }
    dicom_tag_templates[:acquisition_matrix_y] = {
      :type => :int,
      :pat => /IMG Columns\/\/ ([0-9]+)/i,
      :required => false
    }
    dicom_tag_templates[:num_slices] = {
      :type => :int,
      :pat => /REL Images in Acquisition\/\/([0-9]+)/i,
      :required => false
    }
    dicom_tag_templates[:bold_reps] = {
      :type => :int,
      :pat => /REL Number of Temporal Positions\/\/([0-9]+)/i,
      :required => false
    }
    dicom_tag_templates[:rep_time] = {
      :type => :float,
      :pat => /ACQ Repetition Time\/\/(.*)\n/i,
      :required => false
    }
    dicom_tag_templates[:date] = {
      :type => :datetime,
      :pat => /ID STUDY DATE\/\/(.*)\n/i #,
      # :required => false
  }
    dicom_tag_templates[:time] = {
      :type => :datetime,
      :pat => /ID Series Time\/\/(.*)\n/i #,
      # :required => false
    }
    
    dicom_tag_templates.each_pair do |name, tag_hash|
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
    dicom_tag_templates[:date][:pat] =~ @hdr_data
    date = $1
    dicom_tag_templates[:time][:pat] =~ @hdr_data
    time = $1
    @timestamp = DateTime.parse(date + time)
    
  end
  
  def printraw_import
    source_pat =               /hospital [Nn]ame: ([[:graph:]\t ]+)/i
    num_slices_pat =           /rdb_hdr_nslices = ([0-9]+)/i
    slice_thickness_pat =      /slthick = ([[:graph:]]+)/i
    slice_spacing_pat =        /scanspacing = ([[:graph:]]+)/i
    date_pat =                 /ex_datetime = (.*)\n/i
    gender_pat =               /patsex = (1|2)/i
    acquisition_matrix_x_pat = /imatrix_X = ([0-9]+)/i
    acquisition_matrix_y_pat = /imatrix_Y = ([0-9]+)/i
    series_description_pat =   /se_desc = ([[:graph:] \t]+)/i
    recon_diam_pat =           /dfov = ([0-9]+)/i
    rmr_number_pat =           /Patient ID for this exam: ([[:graph:]]+)/i
    bold_reps_pat =            /nex = ([0-9]+)/i
    rep_time_pat =             /reptime = ([0-9]+)/i      # not sure ifg this is right
    study_uid_pat =            /Ssop_uid = ([[:graph:]]+)/i
    series_uid_pat =           /series_uid = ([[:graph:]]+)/i
    image_uid_pat =            /image_uid = (.*)/i #([[:graph:]]+)/i   


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
    @timestamp = Time.at($1.to_i).to_datetime
    # @timestamp = DateTime.parse($1)  --- 2 rows- same start of line- first since epoch, 2nd date stamnp
    
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
    
    study_uid_pat =~ @hdr_data
    @study_uid = ($1).strip.chomp unless $1.nil?
    
    series_uid_pat =~ @hdr_data
    @series_uid = ($1).strip.chomp unless $1.nil?
    
    image_uid_pat =~ @hdr_data
    @image_uid = ($1).strip.chomp unless $1.nil?

  end

  # Extracts a collection of metadata from @hdr_data retrieved using the rdgehdr
  # utility. 
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
    study_uid_pat =            /Study entity unique ID: ([[:graph:]]+)/i
    series_uid_pat =           /Series entity unique ID: ([[:graph:]]+)/i
    image_uid_pat =            /Image unique ID: ([[:graph:]]+)/i    

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
    
    study_uid_pat =~ @hdr_data
    @study_uid = ($1).strip.chomp unless $1.nil?
    
    series_uid_pat =~ @hdr_data
    @series_uid = ($1).strip.chomp unless $1.nil?
    
    image_uid_pat =~ @hdr_data
    @image_uid = ($1).strip.chomp unless $1.nil?
    
  end
 
end