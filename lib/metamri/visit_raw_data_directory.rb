require 'rubygems'
require 'pathname'
require 'tempfile'
require 'yaml'
require 'tmpdir'
require 'fileutils'
require 'sqlite3'  # being used in code with inserts and things?????
require 'logger'
require 'pp'
require 'metamri/raw_image_file'
require 'metamri/raw_image_dataset'

# A shared function that displays a message and the date/time to standard output.
def flash(msg)
  flash_size =msg.size + 20
  
  puts
  puts "+" * flash_size
  printf "\t%s\n", msg
  printf "\t%s\n", Time.now
  puts "+" * flash_size
  puts
  $LOG.debug msg if $LOG
end



# Encapsulates a directory of data acquired during one participant visit. These
# are the raw data directories that are transfered directly from the scanners
# and archived in the raw data section of the vtrak filesystem. After
# initializing, the visit can be scanned to extract metadata for all of the
# images acquired during the visit. The scanning is done in a fairly naive
# manner: the visit directory is recursively walked and in each subdirectory any
# and all pfiles will be imported in addition to one single dicom if any exist.
# Thus, only a single dicom file among many in a scan session is used to
# retrieve information. checking the individual files for data integrity must be
# handled elsewhere if at all.
class VisitRawDataDirectory
  # The absolute path of the visit directory, as a string.
  attr_reader :visit_directory
  # An array of :RawImageDataset objects acquired during this visit.
  attr_accessor :datasets
  # Timestamp for this visit, obtained from the first :RawImageDataset
  attr_accessor :timestamp
  # RMR number for this visit.
  attr_accessor :rmr_number
  # scan_procedure name
  attr_reader :scan_procedure_name
  # scanner source
  attr_accessor :scanner_source
  # scanner-defined study id / exam number
  attr_accessor :exam_number
  #
  attr_accessor :db
  # Scan ID is the short name for the scan (tbiva018, tbiva018b)
  attr_accessor :scanid
  # The id of the visit to be used when doing reverse-lookup in data panda.
  attr_accessor :database_id
  # DICOM Study UID (Visit/Study Unique Identifier)
  attr_reader :dicom_study_uid
  
  PREPROCESS_REPOSITORY_DIRECTORY = '/Data/vtrak1/preprocessed/visits' unless defined?(PREPROCESS_REPOSITORY_DIRECTORY)
  DATAPANDA_SERVER = 'http://nelson' unless defined?(DATAPANDA_SERVER)
  # DATAPANDA_SERVER = 'http://localhost:3000' unless defined?(DATAPANDA_SERVER)

  
  # A new Visit instance needs to know the path to its raw data and scan_procedure name.  The scan_procedure
  # name must match a name in the database, if not a new scan_procedure entry will be inserted.
  def initialize(directory, scan_procedure_name=nil)
    raise(IOError, "Visit directory not found: #{directory}") unless File.directory? File.expand_path(directory)
    @visit_directory = File.expand_path(directory)
    @working_directory = Dir.tmpdir
    @datasets = Array.new
    @timestamp = nil
    @rmr_number = nil
    @scan_procedure_name = scan_procedure_name.nil? ? get_scan_procedure_based_on_raw_directory : scan_procedure_name
    @db = nil
    @exam_number = nil
    initialize_log
  end
  
  # Recursively walks the filesystem inside the visit directory.  At each subdirectory, any and all
  # pfiles are scanned and imported in addition to one and only one dicom file.  After scanning
  # @datasets will hold an array of ImageDataset instances.  Setting the rmr here can raise an 
  # exception if no valid rmr is found in the datasets, be prepared to catch it.
  #
  # === Options
  # 
  # * <tt>:ignore_patterns</tt> -- Array of Regex'es. An array of Regular Expressions that will be used to skip heavy directories.
  # 
  def scan(options = {})
    flash "Scanning visit raw data directory #{@visit_directory}" if $LOG.level <= Logger::INFO
    default_options = {:ignore_patterns => []}
    options = default_options.merge(options)
    unless options[:ignore_patterns].empty?
      puts "Ignoring directories matching: #{options[:ignore_patterns].join(", ")}" if $LOG.level <= Logger::INFO
    end
    
    d = Pathname.new(@visit_directory)
    d.each_subdirectory do |dd|
      begin
        matches = options[:ignore_patterns].collect {|pat| dd.to_s =~ pat ? dd : nil }.compact
        next unless matches.empty?
        dd.each_pfile  { |pf| @datasets << import_dataset(pf, dd); @datasets.last.print_scan_status if $LOG.level == Logger::INFO }
        dd.first_dicom { |fd| @datasets << import_dataset(fd, dd); @datasets.last.print_scan_status if $LOG.level == Logger::INFO }
      rescue StandardError => e
        raise(e, "There was an error scaning dataset #{dd}: #{e}")
      end
    end
    
    unless @datasets.size == 0
      @timestamp = get_visit_timestamp
      @rmr_number = get_rmr_number
      @scanner_source = get_scanner_source
      @exam_number = get_exam_number
      @study_uid = get_study_uid unless dicom_datasets.empty?
      flash "Completed scanning #{@visit_directory}" if $LOG.level <= Logger::DEBUG
    else
      raise(IndexError, "No datasets could be scanned for directory #{@visit_directory}")
    end
  end
  
  # use this to initialize Visit objects in the rails app
  def attributes_for_active_record
    { 
      :date => @timestamp.to_s, 
      :rmr => @rmr_number, 
      :path => @visit_directory, 
      :scanner_source => @scanner_source ||= get_scanner_source,
      :scan_number => @exam_number,
      :dicom_study_uid => @study_uid
    }
  end
  
  # Inserts each dataset in this visit into the specified database.  The specifics
  # of the database insert are handled by the #RawImageDataset class.
  def db_insert!(db_file)
    @db = SQLite3::Database.new(db_file)
    @db.results_as_hash = true
    @db.type_translation = true
    
    begin
      # checks scan_procedure in db, inserts if neccessary, returns id
      scan_procedure_id = fetch_or_insert_scan_procedure
      
      # insert or update visit as needed
      if visit_is_new? # this is a new visit
        visit_id = insert_new_visit(scan_procedure_id)    
      else # visit already exists in DB
        visit_id = get_existing_visit_id
        update_existing_visit(visit_id, scan_procedure_id)
      end
    
      # insert each dataset from the visit, also insert an entry in series descriptions table if necessary.
      @datasets.each do |dataset|
        update_series_descriptions_table(dataset.series_description)
        if dataset_is_new?(dataset)
          insert_new_dataset(dataset, visit_id)
        else # dataset is already in DB
          dataset_id = get_existing_dataset_id(dataset)
          update_existing_dataset(dataset, dataset_id)
        end
      end
    rescue Exception => e
      puts e.message
      puts e.backtrace
    ensure
      @db.close
      @db = nil
    end
  end
  
  def default_preprocess_directory
    return File.join(PREPROCESS_REPOSITORY_DIRECTORY, scan_procedure_name, scanid)
  end
  
=begin rdoc
Walks through the dicom datasets in this Scan Visit directory and performs naive file conversion to nifti format, which is useful for basic quality checking.
Accepts an output directory as an optional argument, defaults to the system temp directory.
Returns an array of the created nifti files.
=end
  def to_nifti!(output_directory = Dir.tmpdir)
    flash "Converting raw data directory #{@visit_directory} to Niftis in #{output_directory}"
    nifti_output_files = Array.new
    
    scan if @datasets.empty? 
        
    @datasets.each do |dataset|
      nifti_output_path = output_directory
      nifti_filename = "#{scanid}_#{dataset.series_description.escape_filename}_#{File.basename(dataset.directory).escape_filename}.nii"

      Pathname.new(dataset.directory).all_dicoms do |dicom_files| 
        nifti_input_path = File.dirname(dicom_files.first)
        nifti_conversion_command, nifti_output_file = dataset.to_nifti!(nifti_output_path, nifti_filename, :input_directory => nifti_input_path, :append_modality_directory => true)
        nifti_output_files << nifti_output_file
      end
    end
    
    return nifti_output_files
  end
  
  def scanid
    @scanid ||= File.basename(visit_directory).split('_')[0]
  end
  
  def to_s
    puts; @visit_directory.length.times { print "-" }; puts
    puts "#{@visit_directory}"
    puts "#{@rmr_number} - #{@timestamp.strftime('%F')} - #{@scanner_source} - #{@exam_number unless @exam_number.nil?}"
    puts
    puts RawImageDataset.to_table(@datasets)
    return
  rescue NameError => e
    puts e
    if @datasets.first.class.to_s == "RawImageDatasetResource"
      @datasets = @datasets.map { |ds| ds.to_metamri_image_dataset }
    end
    
    # puts @datasets.first.class.to_s
    # puts @datasets
    
    # Header Line
    printf "\t%-15s %-30s [%s]\n", "Directory", "Series Description", "Files"
    
    # Dataset Lines
    @datasets.sort_by{|ds| [ds.timestamp, File.basename(ds.directory)] }.each do |dataset|
      printf "\t%-15s %-30s [%s]\n", File.basename(dataset.directory), dataset.series_description, dataset.file_count
    end
    
    # Reminder Line
    puts "(This would be much prettier if you hirb was installed (just type: gem install hirb)."
    
    return
  end
  
  
  private
  
  def get_existing_dataset_id(ds)
    @db.execute(ds.db_fetch).first['id']
  end
  
  def update_existing_dataset(ds, ds_id)
    @db.execute(ds.db_update(ds_id))
  end
  
  def insert_new_dataset(ds, v_id)
    @db.execute(ds.db_insert(v_id))
  end
  
  def dataset_is_new?(ds)
    @db.execute(ds.db_fetch).empty?
  end
  
  def visit_is_new?
    @db.execute(sql_fetch_visit_matches).empty?
  end
  
  def update_series_descriptions_table(sd)
    if @db.execute(sql_fetch_series_description(sd)).empty?
      @db.execute(sql_insert_series_description(sd))
    end
  end
  
  def insert_new_visit(p_id)
    puts sql_insert_visit
    @db.execute(sql_insert_visit)
    visit_id = @db.last_insert_row_id
    puts sql_insert_scan_procedures_visits(p_id, visit_id)
    @db.execute(sql_insert_scan_procedures_visits(p_id, visit_id))
    return visit_id
  end
  
  def get_existing_visit_id
    return @db.execute(sql_fetch_visit_matches).first['id']
  end
  
  # ScanProcedure now in a separate table
  # Ignore it for now. BAD! 
  # Note: wtf
  def update_existing_visit(v_id, p_id)
    puts sql_update_visit(v_id)
    @db.execute(sql_update_visit(v_id))
  end
  
  def fetch_or_insert_scan_procedure
    # if the scan_procedure already exists in db use it, if not insert a new one
    scan_procedure_matches = @db.execute(sql_fetch_scan_procedure_name)
    if scan_procedure_matches.empty?
      @db.execute(sql_insert_scan_procedure)
      new_scan_procedure_id = @db.last_insert_row_id
    end
    return scan_procedure_matches.empty? ? new_scan_procedure_id : scan_procedure_matches.first['id']
  end
  
  def sql_update_visit(v_id)
    "UPDATE visits SET 
    date = '#{@timestamp.to_s}',
    rmr = '#{@rmr_number}',
    path = '#{@visit_directory}',
    scanner_source = '#{@scanner_source}'
    WHERE id = '#{v_id}'"
  end
  
  def sql_insert_scan_procedure
    "INSERT INTO scan_procedures (codename) VALUES ('#{@scan_procedure_name}')"
  end
  
  def sql_insert_scan_procedures_visits(scan_procedure_id, visit_id)
    "INSERT INTO scan_procedures_visits (scan_procedure_id, visit_id) VALUES('#{scan_procedure_id}', '#{visit_id}')"
  end
  
  def sql_insert_series_description(sd)
    "INSERT INTO series_descriptions (long_description) VALUES ('#{sd}')"
  end
  
  def sql_fetch_visit_matches
    "SELECT id FROM visits WHERE rmr == '#{@rmr_number}'"
  end
  
  def sql_fetch_scan_procedure_name
    "SELECT * FROM scan_procedures WHERE codename = '#{@scan_procedure_name}' LIMIT 1"
  end
  
  def sql_fetch_series_description(sd)
    "SELECT * FROM series_descriptions WHERE long_description = '#{sd}'"
  end
  
  def sql_fetch_dataset_matches(ds)
    "SELECT * FROM image_datasets WHERE rmr = '#{ds.rmr_number}' AND path = '#{ds.directory}' AND timestamp = '#{ds.timestamp}'"
  end
  

  # generates an sql insert statement to insert this visit with a given participant id
  def sql_insert_visit
    "INSERT INTO visits 
    (date, scan_number, initials, rmr, radiology_outcome, notes, transfer_mri, transfer_pet,
    conference, compile_folder, dicom_dvd, user_id, path, scanner_source, created_at, updated_at) 
    VALUES 
    ('#{@timestamp.to_s}', '', '', '#{@rmr_number}', 'no', '', 'yes', 'no', 
    'no', 'no', '', NULL, '#{@visit_directory}', '#{@scanner_source}', '#{DateTime.now}', '#{DateTime.now}')"
  end

  # Build a new RawImageDataset from a path to the rawfile and parent directory.
  # == Args
  #  * rawfile: String.  Path to the raw image file to scan.  This should be an unzipped PFile or DICOM, ideally on a local disk for speed.
  #  * original_parent_directory: String or Pathname. Path of the original parent directory where the RawImageFile resides.
  # 
  # Raises an IOError with description if the RawImageFile could not be initialized.
  # 
  # Returns a RawImageDataset built from the directory and single rawfile.
  def import_dataset(rawfile, original_parent_directory)
    puts "Importing scan session: #{original_parent_directory.to_s} using raw data file: #{rawfile.basename}" if $LOG.level <= Logger::DEBUG
    
    begin
      rawimagefile = RawImageFile.new(rawfile.to_s)
    # rescue StandardError => e
      # puts e.backtrace
      # raise(e, "+++ Trouble reading raw image file #{rawfile}. #{e}")
    end
    
    return RawImageDataset.new(original_parent_directory.to_s, [rawimagefile])
  end
  
  
  def convert_dataset(rawfiles, original_parent_directory, nifti_output_directory)
    puts "Converting scan session: #{original_parent_directory.to_s} using raw data file: #{rawfiles.first.basename}"
    rawimagefiles = []

    rawfiles.each do |rawfile|
      begin
        rawimagefiles << RawImageFile.new(rawfile.to_s)
      rescue Exception => e
        raise(IOError, "Trouble reading raw image file #{rawfile}. #{e}")
      end
    end
    
    dataset = RawImageDataset.new(original_parent_directory.to_s, rawimagefiles)
    dataset.to_nifti()
    
    #return RawImageDataset.new(original_parent_directory.to_s, rawimagefiles)
    
  end
  
  def get_visit_timestamp
    (@datasets.sort_by { |ds| ds.timestamp }).first.timestamp
  end
  
  # retrieves a valid rmr number from the visit's collection of datasets.  Some datasets out there 
  # have "rmr not found" set in the rmr_number attribute because their header info is incomplete.
  # Throws an Exception if no valid rmr is found
  def get_rmr_number
    @datasets.each do |ds|
      return ds.rmr_number unless ds.rmr_number == "rmr not found"
    end
    raise(IOError, "No valid RMR number was found for this visit")
  end
  
  # retrieves a scanner source from the collection of datasets, raises Exception of none is found
  def get_scanner_source
    raise IOError, "No datasets available, can't look for a scanner source" if @datasets.empty?
    @datasets.each do |ds|
      return ds.scanner_source unless ds.scanner_source.nil?
    end
    raise(IOError, "No valid scanner source found for this visit")
  end
  
  # retrieves exam number / scan id from first #RawImageDataset
  def get_exam_number
    @datasets.each do |ds|
      return ds.exam_number unless ds.exam_number.nil?
    end
    # raise(IOError, "No valid study id / exam number found.")
  end
  
  # retrieves exam number / scan id from first #RawImageDataset
  def get_study_uid
    @datasets.each do |ds|
      return ds.dicom_study_uid unless ds.dicom_study_uid.nil?
    end
    raise(IOError, "No valid study uid found from DICOMS.")
  end
  
  def get_scan_procedure_based_on_raw_directory
    case @visit_directory
    when /alz_2000.*_2$/
      return 'johnson.alz.visit2'
    when /alz_2000.*_3$/
      return 'johnson.alz.visit3'
    when /alz_2000.alz...$/
      return 'johnson.alz.visit1'
    when /alz_2000/
      return 'johnson.alz.unk.visit'
      
    when /tbi_1000.*_2$/
      return 'johnson.tbi-1000.visit2'
    when /tbi_1000.*_3$/
      return 'johnson.tbi-1000.visit3'
    when /tbi_1000.tbi...$/
      return 'johnson.tbi-1000.visit1'
    when /tbi_1000/
      return 'johnson.tbi-1000.unk.visit'
      
    when /tbi_aware.*_2$/
      return 'johnson.tbi-aware.visit2'
    when /tbi_aware.*_3$/
      return 'johnson.tbi-aware.visit3'
    when /tbi_aware.tbi...$/
      return 'johnson.tbi-aware.visit1'
    when /tbi_aware/
      return 'johnson.tbi-aware.unk.visit'

    when /johnson.tbi-va.visit1/
      return 'johnson.tbi-va.visit1'
    
    when /pib_pilot_mri/
      return 'johnson.pibmripilot.visit1.uwmr'

    when /wrap140/
      return 'johnson.wrap140.visit1'
      
    when /cms.uwmr/
      return 'johnson.cms.visit1.uwmr'
    when /cms.wais/
      return 'johnson.cms.visit1.wais'
      
    when /esprit.9month/
      return 'carlsson.esprit.visit2.9month'
    when /esprit.baseline/
      return 'carlsson.esprit.visit1.baseline'
      
    when /gallagher_pd/
      return 'gallagher.pd.visit1'
      
    when /pc_4000/
      return 'johnson.pc4000.visit1'
      
    when /ries.aware.visit1/
      return 'ries.aware.visit1'
      
    when /carlson.sharp.visit1/
      return 'carlson.sharp.visit1'
    
    else
      return 'unknown.scan_procedure'
    end
  end
  
  def dicom_datasets
    dicom_sets ||= []
    datasets.each {|ds| dicom_sets << ds if ds.dicom?}
    return dicom_sets
  end
    
  def initialize_log
    # If a log hasn't been created, catch that here and go to STDOUT.
    unless $LOG
      $LOG = Logger.new(STDOUT)
      $LOG.level = Logger::DEBUG
    end
  end

end
