class Algorithm::Classifier::Meta::KnnVoter < Algorithm::Classifier::Meta::Knn


  def set_settings(tr)
    @zones_threshold = tr
    @optimization = Optimization::ZonalLeastSquares.new
    self
  end

  private



  def model_run_method(table, algorithms, train_height, test_height, tag_id)
    tag_vector = get_tag_vector(algorithms, train_height, test_height, tag_id)

    dominant_zones = dominant_zones_by_voter(tag_vector)
    return dominant_zones.first if dominant_zones.length == 1

    table_part = table_part_with_tag_vector_zones(table, tag_vector)
    compare_tag_vector_vs_table_vectors(table_part, tag_vector)
    nearest_neighbour = get_nearest_neighbour(table_part)
    return nil if nearest_neighbour.nil?
    nearest_neighbour.last[:output]
  end

  def dominant_zones_by_voter(tag_vector)
    threshold_count = tag_vector.length * @zones_threshold
    tag_vector.values.frequency.select{|zone, count| count > threshold_count}.keys
  end

end