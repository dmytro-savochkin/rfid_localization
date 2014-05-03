class Algorithm::Classifier::Meta::Probabilistic::Min < Algorithm::Classifier::Meta::Probabilistic

  private

  def default_value
    []
  end

  def adding_method
    :push
  end

  def process_probabilities(probabilities)
    probabilities.each do |zone_number, current_zone_probabilities|
      probabilities[zone_number] = current_zone_probabilities.min
    end
    probabilities
  end

end