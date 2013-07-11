class MeasurementInformation::Rr < MeasurementInformation::Base
  MINIMAL_POSSIBLE_MI_VALUE = 0.0

  def initialize(rr, reader_power)
    @rr = rr
    @reader_power = reader_power
  end

  def self.to_distance(rr, angle, antenna, height, reader_power)
    model = Regression::RegressionModel.where({:height => height,
                                               :reader_power => reader_power,
                                               :antenna_number => antenna,
                                               :type => 'one',
                                               :mi_type => 'rr'
                                              }).first

    distance = 1.0 * (
        model.const.to_f +
        model.mi_coeff.to_f * rr +
        model.angle_coeff.to_f * rr * Math.cos(angle)
    )

    [distance, 0.0].max
  end

  def self.to_distance_old(rr, angle = 1, height = 41, reader_power = 20, antenna = 1)
    rr = rr.to_f
    return 0 if rr >= 1.0
    return 100 if rr <= 0.1
    7 / rr
  end


  def self.default_value
    0.0
  end

  def self.abs_range
    [0.0, 1.0]
  end
end