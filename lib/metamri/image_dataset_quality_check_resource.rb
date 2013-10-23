# encoding: utf-8
# An ImageQualityCheckResource is a ruby object that represents a quality check
# pulled down from the DataPanda database.  It contains notes on the quality of
# specific images, with a note for each possible problem, and an overall note.
# 
#  Omnibus f:  NA –
#  User: erik
#  Motion warning: NA –
#  Ghosting wrapping:  Pass –
#  Nos concerns: NA –
#  Image dataset:  12136
#  Banding:  Pass –
#  Fov cutoff: Pass –
#  Registration risk:  Pass –
#  Field inhomogeneity:  Mild – eh - it's ok.
#  Other issues: la la la
#  Incomplete series:  Complete –
#  Spm mask: NA –
#  Garbled series: Pass –
# 
# Check the current schema.db file for all available fields.
class ImageDatasetQualityCheckResource < ActiveResource::Base
  self.site = VisitRawDataDirectory::DATAPANDA_SERVER
  self.element_name = "image_dataset_quality_check"
  
  PASSING_STATUSES = Set.new(%w(complete pass))
  FAILING_STATUSES = Set.new( ["Incomplete","Mild","Moderate","Severe","Limited Activation","No activation","No pass"] )
  
  # Returns an array of hashes for failed checks.
  def failed_checks
    failed_checks = Array.new
    self.attribute_names.each_pair do |name, value|
      unless name.blank?
        if FAILING_STATUSES.include?(value)
          comment = instance_values['attributes']["#{name}_comment"]
          failed_checks << {:name => name, :value => value, :comment => comment }
        end
      end
    end
    return failed_checks
  end
  
  def attribute_names
    instance_values['attributes']
  end
    
end