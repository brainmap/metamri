# encoding: utf-8
require 'mysql'

class Mysql
  def summary
    self.list_tables.each do |tbl|
      next if tbl =~ /^tws/
      puts "+" * 160
      puts "%80s" % tbl
      puts "+" * 160
      columns = self.query("select * from #{tbl}").fetch_hash.keys
      columns.in_chunks_of(6).each do |chunk|
        puts "%-25s " * chunk.size % chunk
      end
      puts "\n\n"
    end
  end
end



class Array
  def chunks(number_of_chunks)
    chunks_of( (self.size/number_of_chunks.to_f).ceil )
  end
  def in_chunks_of(chunk_size)
    nchunks = (self.size/chunk_size.to_f).ceil
    chunks = Array.new(nchunks) { [] }
    self.each_with_index do |item,index|
      chunks[ index/chunk_size ] << item
    end
    return chunks
  end
end