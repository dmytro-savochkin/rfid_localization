class Algorithm::Classifier::Meta::Probabilistic::NearestMean < Algorithm::Classifier::Meta::Probabilistic

  private

  def create_template_by_profiles(profiles)
    template = []

    tags_count_in_zones = {}

    profiles.each_with_index do |profiles_part, algorithm_index|
      template[algorithm_index] ||= zero_zone_probabilities
      profiles_part.each do |tag_index, probabilities|
        probabilities.each do |zone_number, probability|
          tags_count_in_zones[zone_number] ||= 0
          tags_count_in_zones[zone_number] += 1
          template[algorithm_index][zone_number] += rescale_confidence(probability)
        end
      end
      (1..16).each do |zone_number|
        template[algorithm_index][zone_number] /= tags_count_in_zones[zone_number]
      end
    end

    template.map{|h| h.values}.flatten
  end





  def set_up_model(model, train_data, setup_data, height_index)
    all_profiles = @algorithms.values.map do |algorithm|
      algorithm[:setup][height_index][:probabilities]
    end

    templates = {}
    (1..16).each do |zone_number|
      zone_profiles = all_profiles.map do |part|
        part.select{|tag_index, tag_probabilities| TagInput.new(tag_index).in_zone?(zone_number)}
      end
      templates[zone_number] = create_template_by_profiles(zone_profiles)
    end

    templates
  end



  def calc_tags_estimates(model, templates, input_tags, height_index)
    tags_estimates = {:probabilities => {}, :estimates => {}}

    comparison = {}
    input_tags.each do |tag_index, tag|
      probabilities = @algorithms.values.map do |algorithm|
        algorithm[:probabilities][height_index][tag_index].values.map{|v| rescale_confidence(v)}
      end.flatten

      (1..16).each do |zone_number|
        comparison_result = @optimization.compare_vectors(probabilities, templates[zone_number], {})
        if @optimization.reverse_decision_function?
          comparison[zone_number] = comparison_result
        else
          comparison[zone_number] = 1.0 / comparison_result
        end
      end

      zone_estimate = Zone.new(comparison.key(comparison.values.max))
      tags_estimates[:probabilities][tag_index] = comparison
      tags_estimates[:estimates][tag_index] = TagOutput.new(tag, zone_estimate.coordinates, zone_estimate)
    end

    tags_estimates
  end

end