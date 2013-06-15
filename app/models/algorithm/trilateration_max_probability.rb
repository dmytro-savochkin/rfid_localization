class Algorithm::TrilaterationMaxProbability < Algorithm::Trilateration


  private

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



  def point_value_for_decision_function(point, antenna, distance)
    sigma_square = 1.8 * (10 ** 7)
    ac = antenna.coordinates

    exp_up = (ac.x - point.x ) ** 2 + ((ac.y + ac.x - point.y - point.x) ** 2) / 1
    exp = (-((exp_up - distance**2) ** 2)) / sigma_square

    Math.exp(exp)
  end
end