class Algorithm::Classifier::Meta::Probabilistic::WeightedZonalSum < Algorithm::Classifier::Meta::Probabilistic::WeightedSum

  private

  def algorithm_weight(weights, zone_number, algorithm_index)
    weights[algorithm_index][zone_number]
  end
end