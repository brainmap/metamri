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
  
  
end