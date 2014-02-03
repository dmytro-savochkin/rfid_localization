class Optimization::Base

  def vectors_to_arrays(vector1, vector2)
    if vector1.is_a? Hash
      array1 = vector1.values
      array2 = vector2.values
    else
      array1 = vector1
      array2 = vector2
    end
    [array1, array2]
  end

  def compare_vectors(vector1, vector2, weights, double_sigma_power = nil)
    raise ArgumentError, "vectors lengths do not match" if vector1.length != vector2.length

    result = default_value_for_decision_function

    array1, array2 = vectors_to_arrays(vector1, vector2)

    array1.each_with_index do |value1, i|
      value2 = array2[i]
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