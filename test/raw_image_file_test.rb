# To change this template, choose Tools | Templates
# and open the template in the editor.

$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'raw_image_file'

class RawImageFileTest < Test::Unit::TestCase
  def setup
    @GEDicom = 'fixtures/I.001'
    @DiDicom = 'fixtures/S4_EFGRE3D.0001'
    @EarlyGEPfile = 'fixtures/P59392.7'
    @LateGEPfile = 'fixtures/P27648.7'
    @notafile = 'fixtures/XXX.XXX'
    @ged = RawImageFile.new(@GEDicom)
    @did = RawImageFile.new(@DiDicom)
    @egep = RawImageFile.new(@EarlyGEPfile)
    @lgep = RawImageFile.new(@LateGEPfile)
  end

  def test_gehdr_dicom_init
    assert_nothing_raised do
      RawImageFile.new(@GEDicom)
    end
  end
  def test_dicomhdr_dicom_init
    assert_nothing_raised do
      RawImageFile.new(@DiDicom)
    end
  end
  def test_early_gehdr_pfile_init
    assert_nothing_raised do
      RawImageFile.new(@EarlyGEPfile)
    end
  end
  def test_late_gehdr_pfile_init
    assert_nothing_raised do
      RawImageFile.new(@LateGEPfile)
    end
  end
  def test_nonfile_init
    assert_raise IOError do
      RawImageFile.new(@notafile)
    end
  end
  def test_pfile?
    assert !@ged.pfile?
    assert !@did.pfile?
    assert @egep.pfile?
    assert @lgep.pfile?
  end
  def test_dicom?
    assert @ged.dicom?
    assert @did.dicom?
    assert !@egep.dicom?
    assert !@lgep.dicom?
  end
  def test_gehdr_dicom_values
    assert_equal "I.001", @ged.filename
    assert_equal "rdgehdr", @ged.hdr_reader
    assert_equal "dicom", @ged.file_type
    assert_equal "2003-01-31T05:02:54+00:00", @ged.timestamp.to_s
    assert_equal "Andys3T", @ged.source
    assert_equal "ALZMRI002", @ged.rmr_number
    assert_equal 1.7, @ged.slice_thickness
    assert_equal 0.3, @ged.slice_spacing
    assert_equal 240.0, @ged.reconstruction_diameter
    assert_equal 256, @ged.acquisition_matrix_x
    assert_equal 256, @ged.acquisition_matrix_y
    assert_equal 9.0, @ged.rep_time
    assert_equal 2, @ged.bold_reps
  end
  def test_dicomhdr_dicom_values
    assert_equal "S4_EFGRE3D.0001", @did.filename
    assert_equal "dicom_hdr", @did.hdr_reader
    assert_equal "dicom", @did.file_type
    assert_equal "2006-11-16T10:59:23+00:00", @did.timestamp.to_s
    assert_equal "Andys3T", @did.source
    assert_equal "RMRRF2267", @did.rmr_number
    assert_equal 1.2, @did.slice_thickness
    assert_equal 1.2, @did.slice_spacing
    assert_equal 240.0, @did.reconstruction_diameter
    assert_equal 256, @did.acquisition_matrix_x
    assert_equal 256, @did.acquisition_matrix_y
    assert_equal 8.364, @did.rep_time
    assert_equal 0, @did.bold_reps
  end
  def test_early_pfile_values
    assert_equal "P59392.7", @egep.filename
    assert_equal "rdgehdr", @egep.hdr_reader
    assert_equal "pfile", @egep.file_type
    assert_equal "2003-01-31T04:39:04+00:00", @egep.timestamp.to_s
    assert_equal "Andys3T", @egep.source
    assert_equal "ALZMRI002", @egep.rmr_number
    assert_equal 4.0, @egep.slice_thickness
    assert_equal 1.0, @egep.slice_spacing
    assert_equal 240.0, @egep.reconstruction_diameter
    assert_equal 64, @egep.acquisition_matrix_x
    assert_equal 64, @egep.acquisition_matrix_y
    assert_equal 1.999996, @egep.rep_time
    assert_equal 124, @egep.bold_reps
  end
  def test_late_pfile_values
    assert_equal "P27648.7", @lgep.filename
    assert_equal "rdgehdr", @lgep.hdr_reader
    assert_equal "pfile", @lgep.file_type
    assert_equal "2006-11-16T04:35:02+00:00", @lgep.timestamp.to_s
    assert_equal "Andys3T", @lgep.source
    assert_equal "RMRRF2267", @lgep.rmr_number
    assert_equal 4.0, @lgep.slice_thickness
    assert_equal 1.0, @lgep.slice_spacing
    assert_equal 240.0, @lgep.reconstruction_diameter
    assert_equal 64, @lgep.acquisition_matrix_x
    assert_equal 64, @lgep.acquisition_matrix_y
    assert_equal 2.000010, @lgep.rep_time
    assert_equal 124, @lgep.bold_reps
  end
  
  def test_db_insert
    @ged.db_insert!('fixtures/development.sqlite3')
    @did.db_insert!('fixtures/development.sqlite3')
    @egep.db_insert!('fixtures/development.sqlite3')
    @lgep.db_insert!('fixtures/development.sqlite3')
  end



  def teardown
    @ged.db_remove!('fixtures/development.sqlite3')
    @did.db_remove!('fixtures/development.sqlite3')
    @egep.db_remove!('fixtures/development.sqlite3')
    @lgep.db_remove!('fixtures/development.sqlite3')
  end
end
