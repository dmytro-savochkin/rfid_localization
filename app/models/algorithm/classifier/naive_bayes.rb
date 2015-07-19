class Algorithm::Classifier::NaiveBayes < Algorithm::Classifier

  private

  def train_model(tags_train_input, height, model_id)
    model = {}

    (1..16).each do |antenna|
      mi_vector = tags_train_input.values.
          map{|tag| tag.answers[@metric_name][:average][antenna] || @mi_class.default_value}
      model[antenna] = mi_vector
    end
    zones = tags_train_input.values.map{|tag| tag.nearest_antenna.number}
    model[:zones] = zones

    model
  end


  def model_run_method(model, setup, tag)
    probabilities_for_zones = Hash.new(1.0)

    answers = tag_answers(tag)
    (1..16).each do |zone|
      (1..16).each do |antenna|
        answer = answers[antenna - 1]
        probabilities_for_zones[zone] *=
            conditional_probability(model[antenna], model[:zones], answer, zone)
      end
    end

    {
        :probabilities => probabilities_for_zones,
        :result_zone => probabilities_for_zones.key(probabilities_for_zones.values.max)
    }
  end


	# probability of tag being in zone (conditional_value) if antenna received main_value
  def conditional_probability(mi_for_current_antenna, tags_zones_vector, current_mi, current_zone)
    probability = 1.0

    indices_of_tags_that_are_in_current_zone = []
    tags_zones_vector.each_with_index do |zone, i|
			if zone == current_zone
				indices_of_tags_that_are_in_current_zone.push(i)
			end
		end

    return 0.0001 if indices_of_tags_that_are_in_current_zone.empty?

    indices_of_tags_that_are_in_current_zone.each do |tag_index|
      mi_in_table = mi_for_current_antenna[tag_index]
      probability *= Math.exp( - (current_mi.to_f - mi_in_table) ** 2 / 50)
    end

    probability
  end

end