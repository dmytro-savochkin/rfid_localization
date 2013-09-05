class Optimization::Base

  def compare_vectors(vector1, vector2, weights, double_sigma_power = nil)
    raise ArgumentError, "vectors lengths do not match" if vector1.length != vector2.length

    result = default_value_for_decision_function
    vector1.each do |i, value1|
      value2 = vector2[i]
      if value1.present? or value2.present?
        result = result.send(method_for_adding, criterion_function(value1, value2, double_sigma_power))
      end
    end

    result
  end


  def optimize_data(data, mean = nil)
    data
  end
end