class MeasurementInformation::Rss < MeasurementInformation::Base
  MINIMAL_POSSIBLE_MI_VALUE = -700.5

  def initialize(rss, reader_power)
    @rss = rss
    @reader_power = reader_power
  end

  def self.to_distance(rss, angle, antenna, height, reader_power)
    rss = -1 * rss

    model = Regression::RegressionModel.where({:height => height,
                                                  :reader_power => reader_power,
                                                  :antenna_number => antenna,
                                                  :type => 'one',
                                                  :mi_type => 'rss'
                                              }).first

    distance = 1.0 * (
        model.const.to_f +
        model.mi_coeff.to_f * rss +
        model.angle_coeff.to_f * rss * Math.cos(angle)
    )

    #raise Exception.new('Negative distance from RSS') if distance < 0.0
    [distance, 0.0].max
  end

  def self.to_distance_old(rss)
    rss = (rss.to_f.abs - 61.0).abs
    return 0.0 if rss < 0
    rss * 5.0
  end
end