class Algorithm::Classifier::UpperBound < Algorithm::Classifier::Combinational

  private

  def calculate_tags_output()

    tags_estimates = {}

    TagInput.tag_ids.each do |tag_index|
      tag = @tags[tag_index]

      if @algorithms.values.reject{|a| a[:map][tag_index].nil? or tag.nil? or a[:map][tag_index][:estimate].to_s != tag.nearest_antenna.coordinates.to_s}.length >= 1
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