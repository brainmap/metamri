$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'spec'
require 'helper_spec'
require 'escoffier'
require 'metamri/core_additions'
require 'metamri/raw_image_dataset'
require 'metamri/raw_image_file'
require 'metamri/raw_image_dataset_thumbnail'

describe "Create a thumbnail png for display." do  
  before(:all) do
    # # Initialize a local scratch directory to hold fixtures for testing if it doesn't already exist.
    # unless File.directory?(VISIT_FIXTURE)
    #   FileUtils.mkdir_p(File.dirname(VISIT_FIXTURE))
    #   FileUtils.cp_r(VISIT_FIXTURE_SRC, VISIT_FIXTURE)
    # end
    # unless File.directory?(VISIT_FIXTURE_UNZIPPED)
    #   FileUtils.cp_r(VISIT_FIXTURE, VISIT_FIXTURE_UNZIPPED)
    #   `find #{VISIT_FIXTURE_UNZIPPED} -name '*.bz2' -exec bunzip2 {} \\;`
    # end
    @fixture_path = File.join($MRI_DATA, 'mrt00000_000_010101', 'dicoms', 's10_cubet2')
  end
  
  before(:each) do
    @tmpdir = Dir.mktmpdir
    Pathname.new(@fixture_path).prep_mise_to(@tmpdir)
    @dataset_wd = File.join(@tmpdir, File.basename(@fixture_path))
    @ds = RawImageDataset.new(@dataset_wd, RawImageFile.new(File.join(@dataset_wd, 's10_cubet2.0001')))
    @valid_thumbnail = File.join('fixtures', 'thumbnail.png')
    @valid_thumbnail_slicer = File.join('fixtures', 'thumbnail_slicer.png')
    @test_niftis = []
  end
  
  it "should create a thumbnail in a tmpdir without a specified path." do
    t = RawImageDatasetThumbnail.new(@ds)
    t.create_thumbnail
    
    File.basename(t.path).should == 'Sag-CUBE-T2.png'
    File.exist?(t.path).should be_true
    File.compare(@valid_thumbnail, t.path).should be true
  end
  
  it "should create a thumbnail with a specified path." do
    output_filename = "/tmp/#{@ds.series_description.escape_filename}.png"
    File.delete(output_filename) if File.exist?(output_filename)
    
    t = RawImageDatasetThumbnail.new(@ds)
    t.create_thumbnail('/tmp/')
    
    t.path.should == output_filename
    File.exist?(t.path).should be_true
    File.compare(@valid_thumbnail, t.path).should be true
    
  end
  
  it "should create a thumbnail with an absolute path to file." do
    output_filename = "/tmp/test.png"
    File.delete(output_filename) if File.exist?(output_filename)
    
    t = RawImageDatasetThumbnail.new(@ds)
    t.create_thumbnail(output_filename)
    
    t.path.should == '/tmp/test.png'
    File.exist?(t.path).should be_true
    File.compare(@valid_thumbnail, t.path).should be true
  end
  
  it "should create a thumbnail with a relative path to file." do
    output_filename = "test.png"
    File.delete(output_filename) if File.exist?(output_filename)
    
    t = RawImageDatasetThumbnail.new(@ds)
    t.create_thumbnail(output_filename)
    
    File.exist?(t.path).should be_true
    File.compare(@valid_thumbnail, t.path).should be true
  end
  
  
  it "should raise a ScriptError if the file could not be created." do
    t = RawImageDatasetThumbnail.new(@ds)
    
    File.stub!(:exist?).and_return(false)
    lambda { t.create_thumbnail }.should raise_error(ScriptError, /Error creating thumbnail/ )
  end
  
  it "should create a thumbnail in a tmpdir without a specified path using FSL Slicer." do
    t = RawImageDatasetThumbnail.new(@ds)
    t.create_thumbnail(nil, {:processor => :slicer})
    
    File.basename(t.path).should == 'Sag-CUBE-T2.png'
    File.exist?(t.path).should be_true
    File.compare(@valid_thumbnail_slicer, t.path).should be true
  end
  
  after(:each) do
    # @test_niftis.flatten.each { |nifti| File.delete(nifti) } unless @test_niftis.empty?
    # [@output_directories, @tmpdir, '/tmp'].flatten.each do |temp_dir|
    #   Dir.foreach(temp_dir) {|f| File.delete(File.join(temp_dir, f)) if File.extname(f) == '.nii'}
    # end
  end
  
end