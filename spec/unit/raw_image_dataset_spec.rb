require 'helper_spec'
require 'logger'
require 'metamri/raw_image_dataset'
require 'metamri/raw_image_file'

describe RawImageDataset, "for a single valid DICOM file" do
  before(:each) do
    # Since a single, anonymized dicom is sufficiently small, provide it in fixtures for testing.
    @valid_dicom_basename = 's03_bravo.0156'
    @valid_dicom = File.join(File.dirname(__FILE__), '..', 'fixtures', @valid_dicom_basename)
    @valid_raw_image_file = RawImageFile.new(@valid_dicom)
  end
  
  it "should have scan series metadata" do
    dataset_dir = File.expand_path File.dirname(@valid_dicom)
    ds = RawImageDataset.new(dataset_dir, @valid_raw_image_file)
    
    ds.dataset_key.should == "ID::2010-11-10T00:00:00+00:00"
    ds.directory.should == dataset_dir
    ds.raw_image_files.first.should == @valid_raw_image_file
    ds.rmr_number.should == "ID"
    ds.scanned_file.should == @valid_dicom_basename
    ds.scanner_source.should == "Institution"
    ds.series_description.should == "Ax FSPGR BRAVO T1"
    ds.exam_number.should == "1405"
    ds.timestamp.should == DateTime.parse("Wed, 10 Nov 2010 00:00:00 +0000")
    ds.study_description.should == "RMRMABRAVOTEST"
    ds.dicom?.should be true
    ds.protocol_name.should == "MERIT220 + TAMI/METS 101"
    ds.operator_name.should == "Operator"
    ds.patient_name.should == "Patient"
    ds.dicom_series_uid.should == "1.2.840.113619.2.260.6945.1176948.30017.1288984188.384"
    ds.dicom_study_uid.should == "1.2.840.113619.6.260.4.1294724594.737.1289407877.724"
  end
end