class Optimization::HellingerDistance < Optimization::LeastSquares

  def compare_vectors(vector1, vector2, weights, double_sigma_power = nil)
    raise ArgumentError, "vectors lengths do not match" if vector1.length != vector2.length

    array1, array2 = vectors_to_arrays(vector1, vector2)

    result = 0.0
    array1.each_with_index do |value1, i|
      value2 = array2[i]
      if value1.present? or value2.present?
        result += (Math.sqrt(value1.abs) - Math.sqrt(value2.abs)) ** 2
      end
    end

    Math.sqrt(result)
  end
end