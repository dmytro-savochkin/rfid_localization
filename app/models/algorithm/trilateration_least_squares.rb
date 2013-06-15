class Algorithm::TrilaterationLeastSquares < Algorithm::Trilateration


  private

  def default_value_for_decision_function
    0.0
  end
  def method_for_adding
    :+
  end

  def reverse_decision_function?
    false
  end

  def estimation_extremum_criterion
    :min
  end
  def estimation_compare_operator
    :<=
  end



  def point_value_for_decision_function(point, antenna, distance)
    ac = antenna.coordinates
    (Math.sqrt((ac.x - point.x)**2 + (ac.y - point.y)**2) - distance)**2
  end
end