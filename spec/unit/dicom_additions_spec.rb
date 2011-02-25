require 'helper_spec'
require 'metamri'

describe 'DicomGroup' do
  before(:each) do
    @group_array = Dir.glob('/tmp/s01_assetcal/s01_assetcal.0*')[0..1]
    @group = DicomGroup.new(@group_array)
    @common = DicomGroup.new(@group_array).find_common_elements
    @test_output_file = File.join(Dir.tmpdir, 'test.dcm')
  end
  it 'should initialize a DicomGroup' do
    grp = DicomGroup.new(@group_array)
    grp.should be_an_instance_of DicomGroup
    grp.dobjects.length.should == 2
  end
  
  it 'should convert files in array to DICOM::DObjects' do
    @group.dobjects.first.should be_an_instance_of DICOM::DObject
  end
  
  it 'should generate a hash of tags with common values' do
    tags = @group.find_common_tags
    tags.length.should == 310
    tags.should be_a_kind_of Hash
    tags.should_not be_empty
  end
  
  it 'should remove differing tags' do
    object_lengths = @group.dobjects.map{|dobj| dobj.to_hash.length}
    common_dobj = @group.find_common_elements
    common_dobj.to_hash.length.should be < @group.dobjects.map { |dobj| dobj.to_hash.length }.max
    # @group.dobjects.map {|dobj| dobj.to_hash.length }.should == object_lengths
  end
  
  it 'should set the DICOM string of common tags' do
    # Create a dicom object to test to make sure that we can read the string.
    # segments = @common.encode_segments(4*1024)
    # @common.send(:insert_missing_meta)
    # File.open('/tmp/dcmstring', 'wb') {|f| f.puts segments}
    # puts dcm = DICOM::DObject.new(segments, :bin => true)
    # puts dcm.errors
    # dcm.read_success.should be_true
    # dcm.print_all
    
    @common.write(@test_output_file)
    @common.write_success.should be_true
    File.exist?(@test_output_file).should be_true
    d = DICOM::DObject.new(@test_output_file)
    d.stream.string.should == 'a'
  end
  
  # after(:each) do
  #   File.delete(@test_output_file) if File.exist?(@test_output_file)
  # end
  
end

describe 'DICOM::DObject' do
  before(:all) do
    @group_array = Dir.glob('/tmp/s01_assetcal/s01_assetcal.0*')[0..1]
  end
  
  it "should respond to to_hash" do
    tags = DICOM::DObject.new(@group_array.first).to_hash
    tags.should be_a_kind_of Hash
    tags.should have_key '0019,1081'
  end
end