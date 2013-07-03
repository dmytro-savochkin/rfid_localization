class MeasurementInformation::Rss < MeasurementInformation::Base
  MINIMAL_POSSIBLE_MI_VALUE = -700.5

  def initialize(rss, reader_power)
    @rss = rss
    @reader_power = reader_power
  end

  def to_distance
    rss = (@rss.to_f.abs - 61.0).abs
    return 0.0 if rss < 0
    rss * 5.0
  end
end