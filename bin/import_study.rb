#!/usr/bin/env ruby
#
# == Synopsis 
#   A simple utility for importing imaging data for an entire study into the WADRC Data Tools web
#   application.  Scans each visit within a particular protocol and inserts all the appropriat meta-data
#   into the given database. Can be run as a command line utility, or the function can be required by other packages.
#
# == Examples
#   import_study.rb alz_1 /path/to/the/rails/db/production.sqlite3
#
# == Usage 
#   import_visit.rb <study_code> <database_file>
#
#   Study codes are one of:
#      alz_1, alz_2, cms_wais, cms_uwmr, esprit_1, esprit_2, gallagher_pd, pib_pilot, ries_pilot, ries_1, 
#      tbi1000_1, tbi1000_2, tbi1000_3, tbiva, wrap140
#
#   For help use: import_visit.rb -h
#
# == Options
#   -h, --help          Displays help message
#
# == Author
#   K.J. Kosmatka, kk4@medicine.wisc.edu
#
# == Copyright
#   Copyright (c) 2009 WADRC Imaging Core.
#

$:.unshift File.join(File.dirname(__FILE__),'..','lib')

require 'visit_raw_data_directory'
require 'pathname'
require 'logger'

#:stopdoc:
STUDIES = {
  :alz_1 =>        { :dir => '/Data/vtrak1/raw/alz_2000',
                     :logfile => 'alz.visit1.scan.log',
                     :filter => /^alz...$|^alz..._[AB]/i,
                     :codename => 'johnson.alz.visit1' 
  },
  :alz_2 =>        { :dir => '/Data/vtrak1/raw/alz_2000',
                     :logfile => 'alz.visit2.scan.log',
                     :filter => /^alz..._2$/,
                     :codename => 'johnson.alz.visit2' 
  },
  :cms_wais =>     { :dir => '/Data/vtrak1/raw/cms/wais',
                     :logfile => 'cms.wais.scan.log',
                     :filter => /^pc/,
                     :codename => 'johnson.cms.visit1.wais' 
  },
  :cms_uwmr =>     { :dir => '/Data/vtrak1/raw/cms/uwmr',
                     :logfile => 'cms.uwmr.scan.log',
                     :filter => /^cms...$/,
                     :codename => 'johnson.cms.visit1.uwmr' 
  },
  :esprit_1 =>     { :dir => '/Data/vtrak1/raw/esprit/baseline',
                     :logfile => 'esprit.baseline.scan.log',
                     :filter => /^esp3/,
                     :codename => 'carlsson.esprit.visit1.baseline' 
  },
  :esprit_2 =>     { :dir => '/Data/vtrak1/raw/esprit/9month',
                     :logfile => 'esprit.9month.scan.log',
                     :filter => /^esp3/,
                     :codename => 'carlsson.esprit.visit2.9month' 
  },
  :gallagher_pd => { :dir => '/Data/vtrak1/raw/gallagher.pd',
                     :logfile => 'gallagher.scan.log',
                     :filter => /^pd..._/,
                     :codename => 'gallagher.pd.visit1' 
  },
  :pib_pilot =>    { :dir => '/Data/vtrak1/raw/pib_pilot_mri',
                     :logfile => 'pib.mri.pilot.scan.log',
                     :filter => /^cpr0/,
                     :codename => 'johnson.pibmripilot.visit1.uwmr' 
  },
  :ries_1 =>       { :dir => '/Data/vtrak1/raw/ries.aware.visit1',
                     :logfile => 'ries.aware.visit1.scan.log',
                     :filter => /^awr0/,
                     :codename => 'ries.aware.visit1' 
  },
  :ries_pilot =>   { :dir => '/Data/vtrak1/raw/ries.aware.visit1',
                     :logfile => 'ries.aware.pilot.scan.log',
                     :filter => /^awrP/,
                     :codename => 'ries.aware.pilot' 
  },
  :tbi1000_1 =>    { :dir => '/Data/vtrak1/raw/tbi_1000',
                     :logfile => 'tbi1000.visit1.scan.log',
                     :filter => /^tbi...$/,
                     :codename => 'johnson.tbi1000.visit1'
  },
  :tbi1000_2 =>    { :dir => '/Data/vtrak1/raw/tbi_1000',
                     :logfile => 'tbi1000.visit2.scan.log',
                     :filter => /^tbi..._2/,
                     :codename => 'johnson.tbi1000.visit2' 
  },
  :tbi1000_3 =>    { :dir => '/Data/vtrak1/raw/johnson.tbi.aware.visit3',
                     :logfile => 'tbiaware.visit3.scan.log',
                     :filter => /^tbi..._3$/,
                     :codename => 'johnson.tbiaware.visit3' 
  },
  :tbiva =>        { :dir => '/Data/vtrak1/raw/johnson.tbi-va.visit1',
                     :logfile => 'tbiva.scan.log',
                     :filter => /^tbi/,
                     :codename => 'johnson.tbiva.visit1' 
  },
  :wrap140 =>      { :dir => '/Data/vtrak1/raw/wrap140',
                     :logfile => 'wrap140.scan.log',
                     :filter => /^wrp/,
                     :codename => 'johnson.wrap140.visit1' 
  }
}
#:startdoc:


# == Function
#   Imports an entire study.
# 
# == Arguments
# study -- a hash specifying the following keys:
#   :dir => the directory holding all the individual visit directories for this study
#   :logfile => a file name where logging can be written
#   :filter => a regex that matches all of the visit directory names that should be scanned
#   :codename => the study codename, e.g. 'johnson.alz.visit1'
#
# dbfile -- the database into which meta-data will be inserted
#
def import_study(study, dbfile)
  studydir = Pathname.new(study[:dir])
  log = Logger.new(study[:logfile], shift_age = 7, shift_size = 1048576)

  studydir.entries.each do |visit|
    next if visit.to_s =~ /^\./
    next unless visit.to_s =~ study[:filter]
    visitdir = studydir + visit
    v = VisitRawDataDirectory.new( visitdir.to_s, study[:codename] )  
    begin
      v.scan
      v.db_insert!(dbfile)
    rescue Exception => e
      puts "There was a problem scanning a dataset in #{visitdir}... skipping."
      puts "Exception message: #{e.message}"
      log.error "There was a problem scanning a dataset in #{visitdir}... skipping."
      log.error "Exception message: #{e.message}"
    ensure
      v = nil
    end
  end
end



if __FILE__ == $0
  study = STUDIES[ARGV[0].to_sym]
  dbfile = ARGV[1]
  import_study(study, dbfile)
end



