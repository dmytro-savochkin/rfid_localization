class Optimization::AngularCosineSimilarity < Optimization::CosineSimilarity
  def compare_vectors(vector1, vector2, weights, double_sigma_power = 1.0)
    raise ArgumentError, "vectors lengths are not equal" if vector1.length != vector2.length
    cosine_similarity = super(vector1, vector2, weights, double_sigma_power)
    1.0 - (Math.acos(cosine_similarity) / Math::PI)
  end
end