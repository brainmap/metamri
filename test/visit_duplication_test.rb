# To change this template, choose Tools | Templates
# and open the template in the editor.

$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'pathname'
require 'metamri'


class RawImageFileTest < Test::Unit::TestCase
  DBFILE = '/Data/home/kris/TextMateProjects/TransferScans/db/development.sqlite3'
  
  def setup
    # DO NOTHING
  end
  
  def test_scan_and_insert
    @v = VisitRawDataDirectory.new( '/Data/vtrak1/raw/alz_2000/alz093', 'ALZ' )
    @v.scan
    @v.init_db(DBFILE)
    @v.db_insert!
  end
end