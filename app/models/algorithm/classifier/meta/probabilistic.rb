class Algorithm::Classifier::Meta::Probabilistic < Algorithm::Classifier::Meta

  private

  def calc_tags_estimates(algorithms, input_tags, train_height, test_height)
    tags_estimates = {:probabilities => {}, :estimates => {}}

    input_tags.each do |tag_index, tag|
      run_results = make_estimate(tag_index, algorithms, train_height, test_height, tag)
      zone_probabilities = run_results[:probabilities]
      zone_estimate = run_results[:result_zone]
      zone = Zone.new(zone_estimate)
      tag_output = TagOutput.new(tag, zone.coordinates, zone)
      tags_estimates[:probabilities][tag_index] = zone_probabilities
      tags_estimates[:estimates][tag_index] = tag_output
    end

    #puts tags_estimates.to_yaml

    tags_estimates
  end




  def make_estimate(tag_index, algorithms, train_height, test_height, tag)
    probabilities = {}

    (1..16).each{|zone_number| probabilities[zone_number] = 1.0}

    puts algorithms.length
    puts tag.answers[:rss][:average].to_s

    algorithms.each do |algorithm_name, algorithm_data|
      algorithm_probabilities = algorithm_data[:probabilities][train_height][test_height]

      if algorithm_probabilities[tag_index].present?
        algorithm_probabilities[tag_index].each do |point, probability|
          zone_number = Zone.number_from_point(point)
          probabilities[zone_number] *= probability
        end
      end

      puts tag_index.to_s  + ' ' + algorithm_name.to_s
      puts algorithm_probabilities[tag_index].to_s
      puts probabilities.to_s
      puts ''
    end



    {
        :probabilities => probabilities,
        :result_zone => probabilities.key(probabilities.values.max)
    }
  end
end