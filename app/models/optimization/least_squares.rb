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
  def gradient_compare_operator
    :<
  end
  def epsilon
    5.0
  end


  def trilateration_criterion_function(point, antenna, distance)
    ac = antenna.coordinates
    antenna_to_tag_distance = Math.sqrt((ac.x.to_f - point.x) ** 2 + (ac.y.to_f - point.y) ** 2)
    criterion_function(antenna_to_tag_distance, distance.to_f)
  end



  def weight_points(points_and_result_ary)
    shift = 0.0001
    total_inverted_probability = points_and_result_ary.map{|e| 1.0 / (e.last.to_f + shift)  }.sum

    points = []
    weights = []
    points_and_result_ary.each do |nearest_neighbour|
      point, probability = *nearest_neighbour
      points.push point
      weights.push((1.0 / (probability + shift)) / total_inverted_probability)
    end

    [points, weights]
  end



  private

  def criterion_function(value1, value2, double_sigma_power = nil)
    (value1 - value2) ** 2
  end

end