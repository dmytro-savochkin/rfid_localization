class Optimization::MaximumProbability < Optimization::Base
  def default_value_for_decision_function
    1.0
  end
  def method_for_adding
    :*
  end

  def reverse_decision_function?
    true
  end

  def estimation_extremum_criterion
    :max
  end
  def estimation_compare_operator
    :>=
  end
  def gradient_compare_operator
    :>
  end
  def epsilon
    0.0001
  end



  def trilateration_criterion_function(point, antenna, distance)
    ac = antenna.coordinates
    exp_up = Math.sqrt( (ac.x - point.x ) ** 2 + ((ac.y + ac.x - point.y - point.x) ** 2) )
    sigma_power = 10 ** 5
    criterion_function(exp_up, distance, sigma_power)
  end




  def weight_points(points_and_result_ary)
    total_probability = points_and_result_ary.map{|e|e.last}.sum

    points = []
    weights = []
    points_and_result_ary.each do |nearest_neighbour|
      point, probability = *nearest_neighbour
      points.push point
      weights.push(probability / total_probability)
    end

    [points, weights]
  end




  private

  def criterion_function(value1, value2, double_sigma_power)
    Math.exp(- (((value1 - value2) ** 2) / double_sigma_power))
  end


end