class Optimization::LeastSquares < Optimization::Base
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


  def optimize_data(data)
    data
  end
  def optimization_data(distances)
    {}
  end


  def trilateration_criterion_function(point, antenna, distance, distances)
    ac = antenna.coordinates
    antenna_to_tag_distance = Math.sqrt((ac.x - point.x)**2 + (ac.y - point.y)**2)
    criterion_function(antenna_to_tag_distance, distance)
  end

  def criterion_function(value1, value2, other_params = {})
    (value1 - value2) ** 2
  end
end