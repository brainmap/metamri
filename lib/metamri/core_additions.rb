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

class Pathname
  MIN_PFILE_SIZE = 10_000_000
  
  def each_subdirectory
    each_entry do |leaf|
      next if leaf.to_s =~ /^\./
      branch = self + leaf
      next if not branch.directory?
      next if branch.symlink?
      branch.each_subdirectory { |subbranch| yield subbranch }
      yield branch
    end
  end
  
  def each_pfile(min_file_size = MIN_PFILE_SIZE)
    entries.each do |leaf|
      next unless leaf.to_s =~ /^P.*\.7|^P.*\.7\.bz2/
      branch = self + leaf
      next if branch.symlink?
      if branch.size >= min_file_size
        lc = branch.local_copy
        begin
          yield lc
        rescue Exception => e
          puts "#{e}"
        ensure
          lc.delete
        end
      end
    end
  end
  
  def first_dicom
    entries.each do |leaf|
      branch = self + leaf
      if leaf.to_s =~ /^I\.|\.dcm(\.bz2)?$|\.0[0-9]+(\.bz2)?$/
        lc = branch.local_copy
        begin
          yield lc
        rescue Exception => e
          puts "#{e}"
        ensure
          lc.delete
        end
        return
      end 
    end
  end
  
  def all_dicoms
    local_copies = []
    Dir.mktmpdir do |tempdir|
      begin
      
        entries.each do |leaf|
          branch = self + leaf
          if leaf.to_s =~ /^I\.|\.dcm(\.bz2)?$|\.0[0-9]+(\.bz2)?$/
            local_copies << branch.local_copy(tempdir)
          end
        end

        yield local_copies

      ensure
        local_copies.each { |lc| lc.delete }
      end
    end
    
    return
  end
  
  def local_copy(tempdir = Dir.tmpdir)
    tfbase = self.to_s =~ /\.bz2$/ ? self.basename.to_s.chomp(".bz2") : self.basename.to_s
    tfbase.escape_filename
    tmpfile = File.join(tempdir, tfbase)
    if self.to_s =~ /\.bz2$/
      `bunzip2 -k -c '#{self.to_s}' >> '#{tmpfile}'`
    else
      FileUtils.cp(self.to_s, tmpfile)
    end
    return Pathname.new(tmpfile)
  end
  
end