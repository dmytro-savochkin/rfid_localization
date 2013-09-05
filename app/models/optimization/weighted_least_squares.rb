class Optimization::WeightedLeastSquares < Optimization::LeastSquares

  def compare_vectors(vector1, vector2, weights, double_sigma_power = nil)
    raise ArgumentError, "vectors lengths do not match" if vector1.length != vector2.length
    if vector1.length != weights.length and weights.length != 0
      raise ArgumentError, "weights lengths do not match vectors length"
    end

    result = default_value_for_decision_function
    vector1.each do |i, value1|
      weight = weights[i] || 1.0
      value2 = vector2[i]
      if value1.present? or value2.present?
        result = result.send(method_for_adding, criterion_function(value1, value2, weight, double_sigma_power))
      end
    end

    result
  end


  def criterion_function(value1, value2, weight, double_sigma_power = nil)
    weight * ((value1 - value2) ** 2)
  end

end