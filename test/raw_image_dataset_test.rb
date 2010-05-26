# To change this template, choose Tools | Templates
# and open the template in the editor.

$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'metamri/raw_image_dataset'
require 'metamri/raw_image_file'

class RawImageDatasetTest < Test::Unit::TestCase
  DBFILE = 'fixtures/development.sqlite3'
  
  def setup
    @aa = RawImageFile.new('fixtures/I.001')
    @bb = RawImageFile.new('fixtures/P27648.7')
    @cc = RawImageFile.new('fixtures/P59392.7')
    @dd = RawImageFile.new('fixtures/S4_EFGRE3D.0001')
    @dset = RawImageDataset.new('/Data/home/kris/NetBeansProjects/ImageData/test/fixtures', [@aa,@bb,@cc,@dd])
  end

  def test_raw_image_files
    assert_equal 4, @dset.raw_image_files.length
    assert_equal '"I.*"', @dset.glob
    assert_equal "SAG T2 W FSE 1.7 skip 0.3", @dset.series_description
    assert_equal "ALZMRI002", @dset.rmr_number
    assert_equal "2003-01-31T04:39:04+00:00", @dset.timestamp.to_s
    assert_equal "ALZMRI002::2003-01-31T04:39:04+00:00", @dset.dataset_key
    assert_equal "DELETE FROM image_datasets WHERE dataset_key = 'ALZMRI002::2003-01-31T04:39:04+00:00'", @dset.db_remove
  end
  
  def test_db_insertion
    assert_raise IndexError do
      @dset.db_insert!(DBFILE)
      @dset.db_insert!(DBFILE)
    end
  end
  
  def test_raw_image_insertion
    @dset.db_insert_raw_images!(DBFILE)
  end

  def teardown
    @dset.db_remove_raw_images!(DBFILE)
    @dset.db_remove!(DBFILE)
  end
end