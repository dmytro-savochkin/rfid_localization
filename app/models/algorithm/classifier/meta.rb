class Algorithm::Classifier::Meta < Algorithm::Classifier

  attr_accessor :algorithms

  def initialize(algorithms)
    @algorithms = algorithms
  end

  def set_settings()
    self
  end


  private

  def create_models_object
    []
  end

  def execute_tags_estimates_search(models, train_height,  test_height)
    calc_tags_estimates(@algorithms, train_height, test_height)
  end

end