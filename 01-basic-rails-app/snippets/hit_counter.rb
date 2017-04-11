class HitCounter < ApplicationRecord

  #TODO: this is totally NOT the right way to implement a hit counter... 
  # there are bugs here in race conditions where we could create multiple counters and where we could mis-count hits

  def self.counter
    @counter ||= first || create!(hits: 0)
  end

  def self.hit!
    counter.update(hits: hits + 1)
  end

  def self.hits
    counter.hits
  end

end
