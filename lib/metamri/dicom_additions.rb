# encoding: utf-8
# Dicom Additions is a test extension of DICOM to allow for gathering common tags
class DicomGroup
  # Array of DObjects to aggregate
  attr_accessor :dobjects
  # Hash of tags shared by all DICOMs in Directory
  attr_reader :tags
  # DICOM::DObject containing all common tags of the group
  attr_reader :common
  
  # Initialize with an array of strings or DICOM::DObjects to aggregate
  def initialize(dicomgroup)
    if dicomgroup.select {|dcm| dcm.is_a? DICOM::DObject }.empty?
      @dobjects = dicomgroup.collect {|dcm| DICOM::DObject.read(dcm)} 
      #@dobjects = dicomgroup.collect {|dcm| DICOM::DObject.new(dcm)}  # changing from dicom 0.8.0  to 0.9.5
    else 
      @dobjects = dicomgroup
    end
  end
  
  # Return a hash of tags and values of elements common to all DICOMs in the group.
  def find_common_tags
    @dobjects.inject(@dobjects.first.to_hash) do |memo, dobj|
      memo = memo.similar(dobj.to_hash)
    end
  end
  
  # Return a new DICOM::DObject containing elements common (identical tags and values) to all DICOMs in the group. 
  def find_common_elements
    @dobjects.inject do |memo, dobj|
      memo.remove_elements_that_differ_from dobj
      memo
    end
  end
  
end

# Reopen DObject to make tag hash
class DICOM::DObject
  # Return hash of {tags => values}
  def to_hash
    taghash = {}
    @tags.each_key {|k| taghash[k] = value(k) }
    return taghash
  end
  
  # Remove elements from a dobj that aren't identical to self's tags.
  def remove_elements_that_differ_from(other_dobj)
    @tags.each_key do |k|
      unless @tags[k].eql? other_dobj[k]
        # pp k, [@tags[k].value, other_dobj[k].value]
        remove k
      end
    end
  end

end

# Reopen DataElement to compare
class DICOM::DataElement
  # Compare data elements on their tag and value
  def eql?(other)
    @tag == other.instance_eval("@tag") && @value == other.value && @bin == other.instance_eval("@bin")
  end
end