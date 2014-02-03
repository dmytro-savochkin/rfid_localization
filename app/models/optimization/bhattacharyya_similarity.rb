class Optimization::BhattacharyyaSimilarity < Optimization::MaximumProbability
  def compare_vectors(vector1, vector2, weights, double_sigma_power = 1.0)
    raise ArgumentError, "vectors lengths are not equal" if vector1.length != vector2.length

    similarity = 0.0

    array1, array2 = vectors_to_arrays(vector1, vector2)
    array1.each_with_index do |value1, i|
      value2 = array2[i]
      similarity += Math.sqrt(value1 * value2)
    end

    similarity
  end

end