class Algorithm::Classifier::Meta::Probabilistic::Sum < Algorithm::Classifier::Meta::Probabilistic

  private

  def default_value
    0.0
  end

  def adding_method
    :+
  end
end