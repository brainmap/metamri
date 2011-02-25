$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'helper_spec'

require 'rubygems'
require 'metamri'

VISIT_FIXTURE_SRC = '/Data/vtrak1/raw/johnson.tbi-va.visit1/tbiva034_10019_04212010'
VISIT_FIXTURE = File.join(Dir.tmpdir, 'fixtures/visit_raw_data_directory/tbiva034_10019_04212010')
VISIT_FIXTURE_UNZIPPED = File.join(Dir.tmpdir, 'fixtures/visit_raw_data_directory/tbiva034_10019_04212010_unzipped')



describe "Convert Unknown Dicoms to Nifti Files" do  
  before(:all) do
    # Initialize a local scratch directory to hold fixtures for testing if it doesn't already exist.
    unless File.directory?(VISIT_FIXTURE)
      FileUtils.mkdir_p(File.dirname(VISIT_FIXTURE))
      FileUtils.cp_r(VISIT_FIXTURE_SRC, VISIT_FIXTURE)
    end
    unless File.directory?(VISIT_FIXTURE_UNZIPPED)
      FileUtils.cp_r(VISIT_FIXTURE, VISIT_FIXTURE_UNZIPPED)
      `find #{VISIT_FIXTURE_UNZIPPED} -name '*.bz2' -exec bunzip2 {} \\;`
    end
  end
  
  before(:each) do
    @visit = VisitRawDataDirectory.new(VISIT_FIXTURE, 'johnson.tbi-va.visit1')
    Pathname.new(File.join(@visit.visit_directory, '001')).first_dicom do |fd|
      @dataset = RawImageDataset.new(
        File.join(VISIT_FIXTURE, '001'), 
        [RawImageFile.new(fd)]
      )
    end
    
    @visit_unzipped = VisitRawDataDirectory.new(VISIT_FIXTURE_UNZIPPED, 'johnson.tbi-va.visit1')
    @dataset_unzipped = RawImageDataset.new(
      File.join(VISIT_FIXTURE_UNZIPPED, '001'), 
      [RawImageFile.new(File.join(VISIT_FIXTURE_UNZIPPED, '001/I0001.dcm'))]
    )
    
    @test_niftis = Array.new
    @output_directories = Array.new
  end

  it "should Convert an anatomical from dicom to nifti using original, unzipped files." do
    @dataset_unzipped.to_nifti('/tmp/', 'filename.nii', :input_directory => @dataset_unzipped.directory)[0].should == "to3d -session /tmp/ -prefix filename.nii #{@dataset_unzipped.directory}/'*.dcm'"
    nifti_conversion_command, nifti_output_file = @dataset_unzipped.to_nifti!('/tmp/', 'filename.nii', :input_directory => @dataset_unzipped.directory)
    nifti_conversion_command.should == "to3d -session /tmp/ -prefix filename.nii #{@dataset_unzipped.directory}/'*.dcm'"
    File.exist?(nifti_output_file).should be_true
    @test_niftis << nifti_output_file
  end
  
  it "should convert all anatomicals in a visit raw directory using original, unzipped files." do
    @visit_unzipped.scan
    
    @visit_unzipped.datasets.each do |ds|
      begin 
        nifti_filename = "#{@visit_unzipped.scanid}_#{ds.series_description.escape_filename}_#{File.basename(ds.directory)}.nii"
        nifti_conversion_commmand, nifti_output_file = ds.to_nifti!(File.join(Dir.tmpdir, @visit_unzipped.default_preprocess_directory), nifti_filename, :input_directory => ds.directory, :append_modality_directory => true )
        @test_niftis << nifti_output_file
      rescue IOError => e
        puts "-- Error: #{e.message}"
      end
    end
    
    @output_directories = File.join(@visit_unzipped.default_preprocess_directory, 'unknown')
  end
  
  it "should convert all anatomicals in a visit raw directory using local copy." do
    @test_niftis << @visit.to_nifti!
  end
  
  it "should create a good to3d command with input directory or dicom files." do 
    nifti_output_path = '/tmp'
    nifti_filename = '001.nii'
    dataset_pathname = Pathname.new(@dataset.directory)
    dataset_pathname.all_dicoms do |dicom_files| 
      nifti_conversion_command, nifti_output_file = @dataset.to_nifti(nifti_output_path, nifti_filename)
      nifti_conversion_command.should == "to3d -session /tmp -prefix 001.nii #{Dir.tmpdir}/'*.dcm'"

      
      nifti_conversion_command, nifti_output_file = @dataset.to_nifti(nifti_output_path, nifti_filename, :input_directory => '/tmp')
      nifti_conversion_command.should == "to3d -session /tmp -prefix 001.nii /tmp/'*.dcm'"

      
      nifti_input_path = File.dirname(dicom_files.first)
      nifti_conversion_command, nifti_output_file = @dataset.to_nifti(nifti_output_path, nifti_filename, :dicom_files => dicom_files)
      nifti_conversion_command.should == "to3d -session /tmp -prefix 001.nii #{dicom_files.each {|dicom| dicom}.join(" ")}"

    end
  end
  
  it "should append a modality if the :append_modality_directory is true." do
    # For an unknown modality:
    nifti_conversion_command, nifti_output_file = @dataset.to_nifti(Dir.tmpdir, 'filename.nii', :append_modality_directory => true)
    nifti_conversion_command.should == "to3d -session #{Dir.tmpdir}/unknown -prefix filename.nii #{Dir.tmpdir}/'*.dcm'"
  end
  
  it "should guess scan id" do
    @visit.scanid.should == 'tbiva034'
    
    v = VisitRawDataDirectory.new('/Data/vtrak1/preprocessed/visits/asthana.adrc-clinical-core.visit1/adrc00001', 'asthana.adrc-clinical-core.visit1')
    v.scanid.should == 'adrc00001'
  end
  
  after(:each) do
    @test_niftis.flatten.each { |nifti| File.delete(nifti) if File.exist?(nifti) } unless @test_niftis.empty?
    [@output_directories, Dir.tmpdir, '/tmp'].flatten.each do |temp_dir|
      Dir.foreach(temp_dir) {|f| File.delete(File.join(temp_dir, f)) if File.extname(f) == '.nii'}
    end
  end
  
end