require 'helper_spec'
require 'metamri/core_additions'
require 'metamri/raw_image_file'


describe RawImageFile, "reads a dicom header and extracts metadata" do
  before(:each) do
    # Since a single, anonymized dicom is sufficiently small, provide it in fixtures for testing.
    @valid_dicom = File.join(File.dirname(__FILE__), '..', 'fixtures', 's03_bravo.0156')
    @valid_serial_dicom_taghash = File.join(File.dirname(__FILE__), '..', 'fixtures', 's03_bravo.0156.yml')
  end
  context "using RubyDicom" do
    it "should successfully set filename" do
      image = RawImageFile.new(@valid_dicom)
      image.filename.should == File.basename(@valid_dicom)
    end
    
    it "should raise an error if the file cannot be found" do
      lambda { RawImageFile.new('bad_path_to.dcm') }.should raise_error(IOError, /File not found/ )
    end
    
    it "should set valid instance variables" do
      valid_dicom_taghash = YAML.load_file(@valid_serial_dicom_taghash)
      
      image = RawImageFile.new(@valid_dicom)
      image.file_type.should == "dicom"
      image.gender.should == "N"
      [RawImageFile::DICOM_HDR, RawImageFile::RDGEHDR, RawImageFile::RUBYDICOM_HDR].include?(image.hdr_reader).should be true
      image.acquisition_matrix_x.should == 256
      image.acquisition_matrix_y.should == 256
      image.num_slices.should == "156"
      image.reconstruction_diameter.should == "256"
      image.rep_time.should == "8.132"
      image.rmr_number.should == "ID"
      image.series_description.should == "Ax FSPGR BRAVO T1"
      image.slice_spacing.should == "1"
      image.slice_thickness.should == "1"
      image.source.should == "Institution"
      # Don't compare floats due to rounding errors, but compare all the other tags in dicom_taghash
      image.dicom_taghash.reject{|k,v| v[:value].kind_of? Float }.should == valid_dicom_taghash.reject{|k,v| v[:value].kind_of? Float }
      image.dicom_study_uid.should == "1.2.840.113619.6.260.4.1294724594.737.1289407877.724"
      image.dicom_series_uid.should == "1.2.840.113619.2.260.6945.1176948.30017.1288984188.384"
    end
  end
end