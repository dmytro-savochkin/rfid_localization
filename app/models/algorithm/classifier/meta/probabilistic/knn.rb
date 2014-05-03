class Algorithm::Classifier::Meta::Probabilistic::Knn < Algorithm::Classifier::Meta::Probabilistic

  def set_settings(optimization, weights = {}, k = 10, filter_length = 3)
    @optimization = optimization
    @k = k
    @filter_length = filter_length
    self
  end

  private


  def set_up_model(model, train_data, setup_data, height_index)
    table = []

    setup_data.each do |tag_index, tag|
      required_probabilities = required_probabilities_for_tag(tag)

      real_probabilities = @algorithms.values.map do |algorithm|
        algorithm[:setup][height_index][:probabilities][tag_index].
            values.map{|v| rescale_confidence(v)}
      end.flatten

      table.push({
          :input => real_probabilities,
          :output => required_probabilities,
          :tag => tag_index
      })
    end

    table
  end




  def filter_vectors(v1, v2, w = {})
    return [v1, v2] if @filter_length == :all
    indices_to_analyze = []

    algorithm_count = v1.length / 16
    [v1, v2].each do |vector|
      algorithm_count.times do |i|
        vector[i*16...(i+1)*16].each_with_index.sort_by{|v|v.first}[-@filter_length..-1].
            each{|v| indices_to_analyze.push(v.last + i*16)}
      end
    end

    indices_to_analyze.uniq!

    [v1.values_at(*indices_to_analyze), v2.values_at(*indices_to_analyze)]
  end


  def calc_tags_estimates(model, setup_model, input_tags, height_index)
    tags_estimates = {:probabilities => {}, :estimates => {}}

    comparison = {}
    input_tags.each do |tag_index, tag|
      probabilities = @algorithms.values.map do |algorithm|
        algorithm[:probabilities][height_index][tag_index].values.map{|v| rescale_confidence(v)}
      end.flatten

      comparison[tag_index] = {}
      setup_model.each_with_index do |neighbor, table_index|
        filtered = filter_vectors(probabilities, neighbor[:input], {})
        comparison_result = @optimization.compare_vectors(filtered[0], filtered[1], {})
        comparison[tag_index][table_index] = comparison_result
      end

      nearest_neighbours = comparison[tag_index].sort_by{|k,v| v}
      nearest_neighbours.reverse! if @optimization.reverse_decision_function?
      k_nearest_neighbours = nearest_neighbours[0...@k]
      table_indices, weights = @optimization.weight_points(k_nearest_neighbours)

      result_probabilities = unity_zone_probabilities
      table_indices.each_with_index do |table_index, weight_index|
        output_probability = setup_model[table_index][:output]
        (1..16).each do |zone_number|
          result_probabilities[zone_number] +=
              output_probability[zone_number] * weights[weight_index]
        end
      end

      zone_estimate = Zone.new(result_probabilities.key(result_probabilities.values.max))
      tags_estimates[:probabilities][tag_index] = result_probabilities
      tags_estimates[:estimates][tag_index] = TagOutput.new(tag, zone_estimate.coordinates, zone_estimate)
    end

    tags_estimates
  end

end