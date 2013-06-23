class MeasurementInformation::Rr < Algorithm::Base
  def initialize(rr, reader_power)
    @rr = rr
    @reader_power = reader_power
  end

  def to_distance
    rr = @rr.to_f
    return 0 if rr >= 1.0
    return 100 if rr <= 0.1
    7 / rr
  end
end