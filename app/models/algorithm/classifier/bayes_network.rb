class Algorithm::Classifier::BayesNetwork < Algorithm::Classifier

  private


  def train_model(tags_train_input)
    model = {}

    (1..16).each do |antenna|
      mi_vector = tags_train_input.values.map{|tag| tag.answers[@metric_name][:average][antenna] || @mi_class.default_value}
      model[antenna] = mi_vector
    end
    zones = tags_train_input.values.map{|tag| tag.nearest_antenna.number}
    model[:zones] = zones

    model
  end


  def model_run_method(model, tag)
    probabilities_for_zones = Hash.new(1.0)

    answers = tag_answers(tag)
    (1..16).each do |zone|
      (1..16).each do |antenna|
        answer = answers[antenna - 1]
        probabilities_for_zones[zone] *= conditional_probability(model[antenna], model[:zones], answer, zone)
      end
    end

    probabilities_for_zones.key(probabilities_for_zones.values.max)
  end


  def conditional_probability(main_vector, conditional_vector, main_value, conditional_value)
    probability = 1.0

    indices = []
    conditional_vector.each_with_index{|value, i| indices.push(i) if value == conditional_value}

    return 0.0001 if indices.empty?

    indices.each do |index|
      v = main_vector[index]
      probability *= Math.exp( - (main_value.to_f - v) ** 2 / 50)
    end

    probability
  end



end