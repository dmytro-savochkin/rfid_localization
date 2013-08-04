class Algorithm::Classifier::Meta::UpperBound < Algorithm::Classifier::Meta::Voter

  private

  def calc_tags_estimates(algorithms, train_height, test_height)
    tags_estimates = {}

    TagInput.tag_ids.each do |tag_index|
      tag = TagInput.new(tag_index)

      algorithms_with_correct_answer = algorithms.values.reject do |a|
        tag.nil? or
            a[:map][train_height][test_height][tag_index].nil? or
            a[:map][train_height][test_height][tag_index][:estimate].to_s != tag.nearest_antenna.coordinates.to_s
      end
      if algorithms_with_correct_answer.length >= 1
        estimate = tag.nearest_antenna.coordinates
      else
        estimate = Point.new(nil, nil)
      end

      zones = Zone.new(Antenna.number_from_point(estimate))
      tag_output = TagOutput.new(tag, estimate, zones)
      tags_estimates[tag_index] = tag_output
    end

    tags_estimates
  end

end