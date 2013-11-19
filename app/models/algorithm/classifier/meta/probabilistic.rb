class Algorithm::Classifier::Meta::Probabilistic < Algorithm::Classifier::Meta

  private

  def calc_tags_estimates(model, setup, input_tags, height_index)
    tags_estimates = {:probabilities => {}, :estimates => {}}


    @rankings = [0,0]

    input_tags.each do |tag_index, tag|
      run_results = make_estimate(tag_index, height_index)
      zone_probabilities = run_results[:probabilities]
      zone_estimate = run_results[:result_zone]
      zone = Zone.new(zone_estimate)
      tag_output = TagOutput.new(tag, zone.coordinates, zone)
      tags_estimates[:probabilities][tag_index] = zone_probabilities
      tags_estimates[:estimates][tag_index] = tag_output
    end



    #puts 'PAY ATTENTION'
    #puts @rankings.to_s
    #puts tags_estimates.to_yaml

    tags_estimates
  end




  def make_estimate(tag_index, height_index)
    probabilities = {}

    rankings = {}

    (1..16).each do |zone_number|
      rankings[zone_number] = 0.0
      probabilities[zone_number] = 1.0
    end

    #puts algorithms.length
    #puts tag.answers[:rss][:average].to_s

    score_for_ranks = [
        1.0, 0.5, 0.25, 0.15,
        0.1, 0.09, 0.08, 0.05,
        0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0
    ]



    @algorithms.each do |algorithm_name, algorithm_data|
      algorithm_probabilities = algorithm_data[:probabilities][height_index]

      if algorithm_probabilities[tag_index].present?

        sorted_probabilities = algorithm_probabilities[tag_index].sort_by{|k,v|v}.reverse
        sorted_probabilities.each_with_index do |(point, probability), rank|
          zone_number = Zone.number_from_point(point)
          rankings[zone_number] += score_for_ranks[rank]
        end


        #puts algorithm_probabilities[tag_index].values.to_s

        probabilities_min = algorithm_probabilities[tag_index].values.select{|prob| prob > 0.0}.min
        probabilities_sum = algorithm_probabilities[tag_index].values.sum
        break if probabilities_sum == 0.0

        algorithm_probabilities[tag_index].each do |point, probability|
          zone_number = Zone.number_from_point(point)
          if probability == 0.0 and probabilities_min.present?
            probabilities[zone_number] *= probabilities_min
          else
            probabilities[zone_number] *= probability
          end
          probabilities[zone_number] /= probabilities_sum
        end
      end

      #puts tag_index.to_s  + ' ' + algorithm_name.to_s
      #puts algorithm_probabilities[tag_index].to_s
      #puts probabilities.to_s
      #puts ''
    end

    #real_zone = TagInput.new(tag_index).zone.to_s
    #zone_by_rankings = rankings.sort_by{|k,v|v}.reverse[0][0].to_s
    #zone_by_probs = probabilities.sort_by{|k,v|v}.reverse[0][0].to_s
    #
    ##max_rank = rankings.values.max
    ##max_prob = probabilities.values.max
    ##zones_by_rankings = rankings.select{|k,v| v == max_rank}.keys
    ##zones_by_probs = probabilities.select{|k,v| v == max_prob}.keys
    #
    ##puts 'probs: ' + probabilities.sort_by{|k,v|v}.reverse.to_s
    ##puts rankings.sort_by{|k,v|v}.reverse.to_s
    #if zone_by_rankings != zone_by_probs
    #  #puts real_zone.to_s
    #  if zone_by_rankings == real_zone
    #    #puts 'RANKINGS_GOOD'
    #    @rankings[0] += 1
    #  end
    #  if zone_by_probs == real_zone
    #    #puts 'RANKINGS_BAD'
    #    @rankings[1] += 1
    #  end
    #end

    {
        :probabilities => probabilities,
        :result_zone => probabilities.key(probabilities.values.max)
    }
  end
end