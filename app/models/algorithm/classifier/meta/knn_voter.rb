class Algorithm::Classifier::Meta::KnnVoter < Algorithm::Classifier::Meta::Knn


  def set_settings(threshold)
    @zones_threshold = threshold
    @optimization = Optimization::ZonalLeastSquares.new
    self
  end

  private


  def model_run_method(table, height_index, tag_id)
    tag_vector = get_tag_vector(height_index, tag_id)

    dominant_zones = dominant_zones_by_voter(tag_vector)
    if dominant_zones.length == 1
      return {
          :result_zone => dominant_zones.first,
          :probabilities => create_probabilities_for_zone(dominant_zones.first)
      }
    end

    table_part = table_part_with_tag_vector_zones(table, tag_vector)
    compare_tag_vector_vs_table_vectors(table_part, tag_vector)
    nearest_neighbour = get_nearest_neighbour(table_part)
    return nil if nearest_neighbour.nil?

    {
        :result_zone => nearest_neighbour.last[:output],
        :probabilities => create_probabilities_for_zone(nearest_neighbour.last[:output])
    }
  end

  def dominant_zones_by_voter(tag_vector)
    threshold_count = tag_vector.length * @zones_threshold
    tag_vector.values.frequency.select{|zone, count| count > threshold_count}.keys
  end

end