# To change this template, choose Tools | Templates
# and open the template in the editor.

$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'test/unit'
require 'visit_raw_data_directory'
require 'pathname'
require 'logger'

class RawImageFileTest < Test::Unit::TestCase
  DBFILE = '/Users/kris/projects/TransferScans/db/development.sqlite3'
  LOG = Logger.new('visit_test.log', shift_age = 7, shift_size = 1048576)
  STUDIES = [
    # Pathname.new('/Data/vtrak1/raw/alz_2000'),
    # Pathname.new('/Data/vtrak1/raw/alz_2000'),
    # Pathname.new('/Data/vtrak1/raw/pib_pilot_mri'),
    # Pathname.new('/Data/vtrak1/raw/johnson.tbi-va.visit1'),
    # Pathname.new('/Data/vtrak1/raw/wrap140'),
    Pathname.new('/Data/vtrak1/raw/cms/uwmr'),
    Pathname.new('/Data/vtrak1/raw/cms/wais'),
    Pathname.new('/Data/vtrak1/raw/esprit/9month'),
    Pathname.new('/Data/vtrak1/raw/esprit/baseline')
    # Pathname.new('/Data/vtrak1/raw/gallagher_pd'),
    #    Pathname.new('/Data/vtrak1/raw/pc_4000'),
    #    Pathname.new('/Data/vtrak1/raw/ries.aware.visit1'),
    #    Pathname.new('/Data/vtrak1/raw/tbi_1000'),
    #    Pathname.new('/Data/vtrak1/raw/tbi_aware')
  ]
  FILTERS = [
    # /^alz...$/,
    # /^alz..._[2AB]$/,
    # /^3..._/,
    # /^tbi/,
    # /^25/,
    /^cms_...$/,
    /^pc...$/,
    /^3.._/,
    /^3.._/
    # /^pd..._/,
    #     /^pc...$/,
    #     /^awr.*\d$/,
    #     /^tbi...$|^tbi..._2$/,
    #     /^tbi..._3$/
  ]
  PROTOCOLS = ['ALZ_visit1','ALZ_visit2','PIB_PILOT','TBI_VA','WRAP140','CMS_UWMR','CMS_WAIS','ESPRIT_9month',
    'ESPRIT_baseline','gallagher_pd','pc_4000','ries.aware.visit1','tbi_1000','tbi_aware']
  
  def setup
    # DO NOTHING
  end
  
  def test_scan_and_insert
    STUDIES.each_with_index do |study, i|
      filter = FILTERS[i]
      protocol = PROTOCOLS[i]
      study.entries.each do |visit|
        next if visit.to_s =~ /^\./
        next unless visit.to_s =~ filter
        visitdir = study + visit
        v = VisitRawDataDirectory.new( visitdir.to_s )
        begin
          v.scan
          v.db_insert!(DBFILE)
        rescue Exception => e
          puts "There was a problem scanning a dataset in #{visitdir}... skipping."
          puts "Exception message: #{e.message}"
          LOG.error "There was a problem scanning a dataset in #{visitdir}... skipping."
          LOG.error "Exception message: #{e.message}"
        ensure
          v = nil
        end
      end
    end
  end
  
end