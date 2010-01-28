
# tried this threaded thing out on zheng but never got it working
# required setting config.active_record.allow_concurrency = true
# in one of the environment config files but still doesn't seem to work
class Array
  def chunk(pieces=2)
    len = self.length;
    mid = (len/pieces)
    chunks = []
    start = 0
    1.upto(pieces) do |i|
      last = start+mid
      last = last-1 unless len%pieces >= i
      chunks << self[start..last] || []
      start = last+1
    end
    chunks
  end

  MAX_NUM_THREADS = 10
  def each_threaded
    num_threads = (self.length > MAX_NUM_THREADS) ? MAX_NUM_THREADS : self.length
    threads = []
    self.chunk(num_threads).each do |chunk|
      threads << Thread.new(chunk) do |items|
        items.each do |item|
          yield(item)
        end
      end
    end
    threads.each {|thr| thr.join}
  end
end