class Algorithm::Classifier::Meta < Algorithm::Classifier

  attr_accessor :algorithms

  def initialize(algorithms, tags_input = nil)
    @algorithms = algorithms
    @tags_input = tags_input
  end

  def set_settings()
    self
  end


  private

  def save_in_file_by_external_mechanism
    false
  end

  def train_model(train_data, heights)
  end

  def set_up_model(model, train_data, setup_data, height_index)
  end

end