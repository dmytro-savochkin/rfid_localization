class Algorithm::Classifier::Meta::Voter < Algorithm::Classifier::Meta

  private

  def calc_tags_estimates(algorithms, train_height, test_height)
    tags_estimates = {}

    TagInput.tag_ids.each do |tag_index|
      tag = TagInput.new(tag_index)
      point_estimate = make_estimate(tag_index, algorithms, train_height, test_height)
      zone = Zone.new( Antenna.number_from_point(point_estimate) )
      tag_output = TagOutput.new(tag, point_estimate, zone)
      tags_estimates[tag_index] = tag_output
    end

    tags_estimates
  end




  def make_estimate(tag_index, algorithms, train_height, test_height)
    hash = {}
    algorithms.each do |algorithm_name, algorithm_data|
      algorithm_map = algorithm_data[:map][train_height][test_height]

      unless algorithm_map[tag_index].nil?
        hash[algorithm_name] ||= algorithm_map[tag_index][:estimate].to_s
      end
    end

    return Point.new(nil,nil) if hash.empty?

    voting_results = hash.values.mode

    if voting_results.length == 1

      Point.from_s(voting_results.first)

    else

      prob = {}

      voting_results.each do |estimate|
        zone_number = Antenna.number_from_point( Point.from_s(estimate) )
        prob[estimate] = 1.0
        current_estimate_algorithms =
            algorithms.
                reject{|n,a| a[:map][train_height][train_height][tag_index].nil?}.
                select{|n,a| a[:map][train_height][train_height][tag_index][:estimate].to_s == estimate}
        current_estimate_algorithms.values.each do |algorithm|
          prob[estimate] *= algorithm[:classification_success][train_height][train_height][zone_number]
        end
      end

      max_vote = prob.values.max
      point_s = prob.select{|point, voting| voting == max_vote}.keys

      Point.from_s( point_s.first )

    end
  end
end