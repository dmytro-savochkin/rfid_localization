class Algorithm::Classifier::Meta::Probabilistic::WeightedSum < Algorithm::Classifier::Meta::Probabilistic::Sum

  private

  def set_up_model(model, train_data, setup_data, height_index)
    weights = {}

    (1..16).to_a.push(:all).each do |zone_number|
      sum = @algorithms.values.map{|a| a[:setup][height_index][:success_rate][zone_number]}.sum
      @algorithms.values.each_with_index do |algorithm, algorithm_index|
        weights[algorithm_index] ||= {}
        weights[algorithm_index][zone_number] =
            algorithm[:setup][height_index][:success_rate][zone_number].to_f / sum
      end
    end
    weights
  end


  def algorithm_weight(weights, zone_number, algorithm_index)
    weights[algorithm_index][:all]
  end
end