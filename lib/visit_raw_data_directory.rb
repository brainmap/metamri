require 'rubygems'
require 'pathname'
require 'tempfile'
require 'yaml'
require 'tmpdir'
require 'fileutils'
require 'raw_image_file'
require 'raw_image_dataset'
require 'sqlite3'


# A shared function that displays a message and the date/time to standard output.
def flash(msg)
  puts
  puts "+" * 120
  printf "\t%s\n", msg
  printf "\t%s\n", Time.now
  puts "+" * 120
  puts
end



=begin rdoc
Encapsulates a directory of data acquired during one participant visit.  These
are the raw data directories that are transfered directly from the scanners and
archived in the raw data section of the vtrak filesystem.  After initializing, the
visit can be scanned to extract metadata for all of the images acquired during the
visit.  The scanning is done in a fairly naive manner: the visit directory is recursively
walked and in each subdirectory any and all pfiles will be imported in addition to one single
dicom if any exist.  Thus, only a single dicom file among many in a scan session is used to 
retrieve information.  checking the individual files for data integrity must be handled
elsewhere if at all.
=end
class VisitRawDataDirectory
  # The absolute path of the visit directory, as a string.
  attr_reader :visit_directory
  # An array of :RawImageDataset objects acquired during this visit.
  attr_reader :datasets
  # Timestamp for this visit, obtained from the first :RawImageDataset
  attr_reader :timestamp
  # RMR number for this visit.
  attr_reader :rmr_number
  # scan_procedure name
  attr_reader :scan_procedure_name
  # scanner source
  attr_reader :scanner_source
  attr_accessor :db
  
  # A new Visit instance needs to know the path to its raw data and scan_procedure name.  The scan_procedure
  # name must match a name in the database, if not a new scan_procedure entry will be inserted.
  def initialize(directory, scan_procedure_name=nil)
    raise(IOError, "Visit directory not found: #{directory}") unless File.exist?(File.expand_path(directory))
    @visit_directory = File.expand_path(directory)
    @working_directory = Dir.tmpdir
    @datasets = Array.new
    @timestamp = nil
    @rmr_number = nil
    @scan_procedure_name = scan_procedure_name.nil? ? get_scan_procedure_based_on_raw_directory : scan_procedure_name
    @db = nil
  end
  
  # Recursively walks the filesystem inside the visit directory.  At each subdirectory, any and all
  # pfiles are scanned and imported in addition to one and only one dicom file.  After scanning
  # @datasets will hold an array of ImageDataset instances.  Setting the rmr here can raise an 
  # exception if no valid rmr is found in the datasets, be prepared to catch it.
  def scan
    flash "Scanning visit raw data directory #{@visit_directory}"
    d = Pathname.new(@visit_directory)
    d.each_subdirectory do |dd|
      dd.each_pfile { |pf| @datasets << import_dataset(pf, dd) }
      dd.first_dicom { |fd| @datasets << import_dataset(fd, dd) }
    end
    @timestamp = get_visit_timestamp
    @rmr_number = get_rmr_number
    @scanner_source = get_scanner_source
    flash "Completed scanning #{@visit_directory}"
  end
  
  # use this to initialize Visit objects in the rails app
  def attributes_for_active_record
    { 
      :date => @timestamp.to_s, 
      :rmr => @rmr_number, 
      :path => @visit_directory, 
      :scanner_source => get_scanner_source,
      :scan_procedure_attributes => { :codename => @scan_procedure_name } 
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
    ensure
      @db.close
      @db = nil
    end
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
    puts sql_insert_visit(p_id)
    @db.execute(sql_insert_visit(p_id))
    return @db.last_insert_row_id
  end
  
  def get_existing_visit_id
    return @db.execute(sql_fetch_visit_matches).first['id']
  end
  
  def update_existing_visit(v_id, p_id)
    puts sql_update_visit(v_id, p_id)
    @db.execute(sql_update_visit(v_id, p_id))
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
  
  def sql_update_visit(v_id, p_id)
    "UPDATE visits SET 
    date = '#{@timestamp.to_s}',
    rmr = '#{@rmr_number}',
    path = '#{@visit_directory}',
    scan_procedure_id = '#{p_id.to_s}',
    scanner_source = '#{@scanner_source}'
    WHERE id = '#{v_id}'"
  end
  
  def sql_insert_scan_procedure
    "INSERT INTO scan_procedures (codename) VALUES ('#{@scan_procedure_name}')"
  end
  
  def sql_insert_series_description(sd)
    "INSERT INTO series_descriptions (long_description) VALUES ('#{sd}')"
  end
  
  def sql_fetch_visit_matches
    "SELECT id FROM visits WHERE rmr == '#{@rmr_number}'"
  end
  
  def sql_fetch_scan_procedure_name
    "SELECT * FROM scan_procedures WHERE codename = '#{@scan_procedure_name}'"
  end
  
  def sql_fetch_series_description(sd)
    "SELECT * FROM series_descriptions WHERE long_description = '#{sd}'"
  end
  
  def sql_fetch_dataset_matches(ds)
    "SELECT * FROM image_datasets WHERE rmr = '#{ds.rmr_number}' AND path = '#{ds.directory}' AND timestamp = '#{ds.timestamp}'"
  end
  
  # generates an sql insert statement to insert this visit with a given participant id
  def sql_insert_visit(scan_procedure_id=0)
    "INSERT INTO visits 
    (date, scan_procedure_id, scan_number, initials, rmr, radiology_outcome, notes, transfer_mri, transfer_pet,
    transfer_behavioral_log, check_imaging, check_np, check_MR5_DVD, burn_DICOM_DVD, first_score, second_score,
    enter_info_in_db, conference, compile_folder, dicom_dvd, user_id, path, scanner_source, created_at, updated_at) 
    VALUES 
    ('#{@timestamp.to_s}', '#{scan_procedure_id.to_s}', '', '', '#{@rmr_number}', 'no', '', 'no', 'no', 
    'no', 'no', 'no', 'no', 'no', 'no', 'no', 'no', 'no', 'no', 'no', NULL, '#{@visit_directory}', #{@scanner_source}, '#{DateTime.now}', '#{DateTime.now}')"
  end
  
  def import_dataset(rawfile, original_parent_directory)
    puts "Importing scan session: #{original_parent_directory.to_s} using raw data file: #{rawfile.basename}"
    return RawImageDataset.new(original_parent_directory.to_s, [RawImageFile.new(rawfile.to_s)])
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
    @datasets.each do |ds|
      return ds.scanner_source unless ds.scanner_source.nil?
    end
    raise(IOError, "No valid scanner source found for this visit")
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
    
    else
      return 'unknown.scan_procedure'
    end
  end

end





class Pathname
  MIN_PFILE_SIZE = 10_000_000
  
  def each_subdirectory
    each_entry do |leaf|
      next if leaf.to_s =~ /^\./
      branch = self + leaf
      next if not branch.directory?
      next if branch.symlink?
      branch.each_subdirectory { |subbranch| yield subbranch }
      yield branch
    end
  end
  
  def each_pfile(min_file_size = MIN_PFILE_SIZE)
    entries.each do |leaf|
      next unless leaf.to_s =~ /^P.*\.7|^P.*\.7\.bz2/
      branch = self + leaf
      next if branch.symlink?
      if branch.size >= min_file_size
        lc = branch.local_copy
        begin
          yield lc
        rescue
          # Do nothing
        ensure
          lc.delete
        end
      end
    end
  end
  
  def first_dicom
    entries.each do |leaf|
      branch = self + leaf
      if leaf.to_s =~ /^I\.|\.dcm(\.bz2)?$|\.0[0-9]+(\.bz2)?$/
        lc = branch.local_copy
        begin
          yield lc
        rescue
          # Do nothing
        ensure
          lc.delete
        end
        return
      end 
    end
  end
  
  def local_copy
    tfbase = self.to_s =~ /\.bz2$/ ? self.basename.to_s.chomp(".bz2") : self.basename.to_s
    tmpfile = File.join(Dir.tmpdir, tfbase)
    if self.to_s =~ /\.bz2$/
      `bunzip2 -k -c #{self.to_s} >> #{tmpfile}`
    else
      FileUtils.cp(self.to_s, tmpfile)
    end
    return Pathname.new(tmpfile)
  end
  
end