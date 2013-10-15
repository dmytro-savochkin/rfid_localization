class Algorithm::Classifier::Meta < Algorithm::Classifier

  attr_accessor :algorithms

  def initialize(algorithms, tags_input)
    @algorithms = algorithms
    @tags_input = tags_input
  end

  def set_settings()
    self
  end


  private

  def create_models_object
    []
  end

  def execute_tags_estimates_search(model, setup, test_data, height_index)
    calc_tags_estimates(@algorithms, test_data, height_index)
  end

end