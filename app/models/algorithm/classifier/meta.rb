class Algorithm::Classifier::Meta < Algorithm::Classifier

  attr_accessor :algorithms

  def initialize(algorithms, manager_id, tags_input = nil)
    @algorithms = algorithms
    @manager_id = manager_id
    @tags_input = tags_input
  end

  def set_settings()
    self
  end


  private

  def train_model(train_data, height, model_id)
  end

  def set_up_model(model, train_data, setup_data, height_index)
  end

end