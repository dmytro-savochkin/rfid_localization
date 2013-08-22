class Algorithm::Classifier::Bayes < Algorithm::Classifier

  private

  def save_in_file_by_external_mechanism
    false
  end


  def train_model(tags_train_input, desired_accuracy)
    bayes_models = {}

    tags_train_input.values.each do |tag|
      nearest_antenna_number = tag.nearest_antenna.number
      (1..16).each do |antenna_number|
        bayes_models[antenna_number] ||= NBayes::Base.new
        answer = tag.answers[@metric_name][:average][antenna_number] || @mi_class.default_value
        if answer != @mi_class.default_value
          bayes_models[antenna_number].train( [answer], nearest_antenna_number )
        else
          bayes_models[antenna_number].train( [answer], nil )
        end
      end
    end

    bayes_models
  end











  def model_run_method(models, tag)
    data = tag_answers(tag)
    model_probabilities, probable_antennae = calc_models_and_probable_antennae(models, data)

    if probable_antennae.length == 1
      probable_antennae.first
    else
      find_most_probable_antenna(model_probabilities)
    end
  end





  def calc_models_and_probable_antennae(models, data)
    model_probabilities = {}
    probable_antennae = []

    (1..16).each do |model_antenna|
      model = models[model_antenna]
      model_probabilities[model_antenna] = model.classify([data[model_antenna - 1]])
      model_most_probable_antenna = model_probabilities[model_antenna].max_class
      probable_antennae.push model_antenna if model_most_probable_antenna == model_antenna
    end

    [model_probabilities, probable_antennae.reject{|a| a.nil?}]
  end





  # find one most probable antenna
  def find_most_probable_antenna(model_probabilities)
    probable_antennae = {}
    (1..16).each do |antenna_number|
      nil_value = model_probabilities[antenna_number].values.max
      normalized_probabilities = normalize(model_probabilities[antenna_number], nil_value)
      cleared_normalized_probabilities = normalized_probabilities.except(nil)
      normalized_probability = cleared_normalized_probabilities[antenna_number]
      probable_antennae[antenna_number] = normalized_probability
    end
    probable_antennae.key(probable_antennae.values.max)
  end

  def normalize(hash, normalize_to)
    hash.map{ |k,v| {k => v / normalize_to} }.reduce(:merge)
  end


end