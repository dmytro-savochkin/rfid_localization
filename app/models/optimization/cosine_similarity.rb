class Optimization::CosineSimilarity < Optimization::MaximumProbability
  def compare_vectors(vector1, vector2, weights, double_sigma_power = 1.0)
    raise ArgumentError, "vectors lengths are not equal" if vector1.length != vector2.length
    ab = 0.0
    a_square = 0.0
    b_square = 0.0

    array1, array2 = vectors_to_arrays(vector1, vector2)
    array1.each_with_index do |value1, i|
      value2 = array2[i]

      if value1.present? or value2.present?
        ab += value1 * value2
        a_square += value1 ** 2
        b_square += value2 ** 2
      end
    end

    cosine_similarity = ab / (Math.sqrt(a_square) * Math.sqrt(b_square))
    cosine_similarity = 1.0 if cosine_similarity > 1.0
    cosine_similarity = -1.0 if cosine_similarity < -1.0
    cosine_similarity
  end
end