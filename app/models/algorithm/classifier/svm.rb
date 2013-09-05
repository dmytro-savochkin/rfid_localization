class Algorithm::Classifier::Svm < Algorithm::Classifier

  private

  def save_in_file_by_external_mechanism
    false
  end

  def model_run_method(model, tag)
    data = tag_answers(tag)
    model.predict(Libsvm::Node.features(*data))
  end



  def train_model(tags_train_input, height)
    svm_problem = Libsvm::Problem.new
    svm_parameter = Libsvm::SvmParameter.new
    svm_parameter.cache_size = 1 # in megabytes
    svm_parameter.eps = 0.0001
    svm_parameter.c = 10

    train_input = []
    train_output = []
    tags_train_input.values.each do |tag|
      nearest_antenna_number = tag.nearest_antenna.number
      train_input.push Libsvm::Node.features(tag_answers(tag))
      train_output.push nearest_antenna_number
    end

    svm_problem.set_examples(train_output, train_input)
    Libsvm::Model.train(svm_problem, svm_parameter)
  end
end