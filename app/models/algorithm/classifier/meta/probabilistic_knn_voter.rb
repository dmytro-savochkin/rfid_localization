class Algorithm::Classifier::Meta::ProbabilisticKnnVoter < Algorithm::Classifier::Meta


  def set_settings(threshold, optimization)
    @zones_threshold = threshold
    @optimization = optimization
    @k = 10
    self
  end

  private


  # эти два метода нужно куда-то вынести
  def probabilities_for_tag(tag)
    probabilities = {}
    (1..16).each do |zone_number|
      zone_score = Zone.distance_score_for_zones(Zone.new(tag.zone), Zone.new(zone_number))
      probabilities[zone_number] = 1.0 / (1.0 + zone_score ** 2)
    end
    probabilities
  end
  def unity_zone_probabilities
    probabilities = {}
    (1..16).each{|zone_number| probabilities[zone_number] = 1.0}
    probabilities
  end





  def set_up_model(model, train_data, setup_data, height_index)
    table = []

    setup_data.each do |tag_index, tag|
      should_be_probabilities = probabilities_for_tag(tag)

      real_probabilities = @algorithms.values.map do |algorithm|
        algorithm[:setup][height_index][:probabilities][tag_index].values
      end.flatten

      table.push({:input => real_probabilities, :output => should_be_probabilities, :tag => tag_index})
    end

    table
  end




  def calc_tags_estimates(model, setup_model, input_tags, height_index)
    tags_estimates = {:probabilities => {}, :estimates => {}}

    comparison = {}
    input_tags.each do |tag_index, tag|
      probabilities = @algorithms.values.map do |algorithm|
        algorithm[:probabilities][height_index][tag_index].values
      end.flatten

      comparison[tag_index] = {}
      setup_model.each_with_index do |neighbor, table_row|
        #puts probabilities.to_s
        #puts neighbor[:input].to_s
        #puts ''

        comparison_result = @optimization.compare_vectors(probabilities, neighbor[:input], {})
        comparison[tag_index][table_row] = comparison_result
      end

      nearest_neighbours = comparison[tag_index].sort_by{|k, v| v}




      nearest_neighbours.reverse! if @optimization.reverse_decision_function?
      k_nearest_neighbours = nearest_neighbours[0...@k]
      table_rows, weights = @optimization.weight_points(k_nearest_neighbours)


      #if tag_index == '0E08'
      #  @algorithms.values.map do |algorithm|
      #    puts algorithm[:probabilities][height_index][tag_index].values.to_s
      #    algorithm[:probabilities][height_index][tag_index].values
      #  end
      #  nearest_neighbours.each do |nn|
      #    puts nn.to_s
      #    puts setup_model[nn.first][:input].to_s
      #    puts setup_model[nn.first][:output].to_s
      #    puts setup_model[nn.first][:tag].to_s
      #    puts ''
      #  end
      #
      #end


      result_probabilities = unity_zone_probabilities
      table_rows.each_with_index do |table_row, i|
        output_probability = setup_model[table_row][:output]
        (1..16).each do |zone_number|
          result_probabilities[zone_number] *= output_probability[zone_number] * weights[i]
        end
      end

      zone_estimate = Zone.new(result_probabilities.key(result_probabilities.values.max))
      tags_estimates[:probabilities][tag_index] = result_probabilities
      tags_estimates[:estimates][tag_index] = TagOutput.new(tag, zone_estimate.coordinates, zone_estimate)
    end

    tags_estimates
  end

end