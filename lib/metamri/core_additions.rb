class String

=begin rdoc
Does same basic string replacements to ensure valid filenames.
=end
  def escape_filename
    mgsub([[/[\s\:\)\(\/\?]+/, "-"], [/\*/, "star"]])
  end
  
  def mgsub(key_value_pairs=[].freeze)
    regexp_fragments = key_value_pairs.collect { |k,v| k }
    gsub(Regexp.union(*regexp_fragments)) do |match|
      key_value_pairs.detect { |k,v| k =~ match}[1]
    end
  end
  
end