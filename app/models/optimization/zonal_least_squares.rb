class Optimization::ZonalLeastSquares < Optimization::LeastSquares

  def criterion_function(value1, value2, double_sigma_power = nil)
    return 0 if value1.nil? and value2.nil?
    return 2 if value1.nil? or value2.nil?
    if value1 > 16 or value1 < 1 or value2 > 16 or value2 < 1
      raise ArgumentError, 'Wrong zone number'
    end
    Zone.distance_score_for_zones(Zone.new(value1), Zone.new(value2)) ** 2
  end

end