class Algorithm::Classifier::Meta::Probabilistic::Product < Algorithm::Classifier::Meta::Probabilistic

  private

  def default_value
    1.0
  end

  def adding_method
    :*
  end
end