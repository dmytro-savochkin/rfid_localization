class Optimization::WeightedLeastSquares < Optimization::LeastSquares

  def compare_vectors(vector1, vector2, weights, double_sigma_power = nil)
    raise ArgumentError, "vectors lengths do not match" if vector1.length != vector2.length
    if vector1.length != weights.length and weights.length != 0
      raise ArgumentError, "weights lengths do not match vectors length"
    end

    result = default_value_for_decision_function
    array1, array2 = vectors_to_arrays(vector1, vector2)
    array1.each_with_index do |value1, i|
      value2 = array2[i]
      weight = weights[i] || 1.0
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