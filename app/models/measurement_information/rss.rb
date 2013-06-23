class MeasurementInformation::Rss < Algorithm::Base
  def initialize(rss, reader_power)
    @rss = rss
    @reader_power = reader_power
  end

  def to_distance
    rss = (@rss.to_f.abs - 61.0).abs
    return 0 if rss < 0
    rss * 5.0
  end

  class << self
    def distances_hash(rss_hash, reader_power)
      distances_hash = {}
      rss_hash.each do |antenna, rss|
        rss_object = self.new(rss, reader_power)
        distances_hash[antenna] = rss_object.to_distance if rss > -70.5
      end
      distances_hash
    end




  end
end