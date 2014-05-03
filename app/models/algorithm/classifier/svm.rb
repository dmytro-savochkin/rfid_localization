class Algorithm::Classifier::Svm < Algorithm::Classifier

  private

  def model_run_method(model, setup, tag)
    data = normalized_tag_answers(tag)
    svm_result = model.predict_probability(Libsvm::Node.features(*data))
    probabilities = {}
    svm_result[1].each_with_index{|confidence, i| probabilities[i + 1] = confidence}

    # SVM regression bug is avoided here somehow
    number_result = svm_result[0]
    probability_result = probabilities.key(probabilities.values.max)
    if number_result.to_i != probability_result.to_i
      max_probability = probabilities.values.sort[-1]
      second_max_probability = probabilities.values.sort[-2]
      probabilities[probability_result] = second_max_probability
      probabilities[number_result.to_i] = max_probability
    end

    {
        :probabilities => probabilities,
        :result_zone => probabilities.key(probabilities.values.max)
        #:result_zone => svm_result[0]
    }
  end



  def train_model(tags_train_input, height, model_id)
    model_string = model_id.to_s.gsub(/[^\d\w,_]/, '')
    file = get_model_file(model_string)
    return Libsvm::Model.load(file) if file.present?

    svm_problem = Libsvm::Problem.new
    svm_parameter = Libsvm::SvmParameter.new
    svm_parameter.cache_size = 10 # in megabytes
    svm_parameter.eps = 0.000001
    svm_parameter.c = 10
    svm_parameter.probability = 1

    train_input = []
    train_output = []
    tags_train_input.values.each do |tag|
      nearest_antenna_number = tag.nearest_antenna.number
      train_input.push Libsvm::Node.features(normalized_tag_answers(tag))
      train_output.push nearest_antenna_number
    end
    svm_problem.set_examples(train_output, train_input)
    model = Libsvm::Model.train(svm_problem, svm_parameter)
    model.save(model_file_dir.to_s + model_file_prefix(model_string) + '_00')

    model
  end



  def model_file_dir
    Rails.root.to_s + '/app/models/algorithm/classifier/models/svm/'
  end
end