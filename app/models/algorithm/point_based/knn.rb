class Algorithm::PointBased::Knn < Algorithm::PointBased

  def trainable
    true
  end



  def set_settings(metric_name, optimization_class, k = 6, weighted = true)
    @k = k
    @weighted = weighted
    @metric_name = metric_name
    @mi_class = MI::Base.class_by_mi_type(metric_name)
    @optimization = optimization_class.new
    self
  end



  def self.make_k_graph(input, metric = :rss, k_values = (1..10))
    k_graph = {:weighted => [], :unweighted => []}
    ([false, true]).each do |weighted|
      k_values.each do |k|
        name = 'knn_' + k.to_s
        knn = Knn.new(input, name).set_settings(metric, k, weighted).output
        k_graph[(weighted ? :weighted : :unweighted)].push([k, knn.mean_error])
      end
    end
    [k_graph[:weighted], k_graph[:unweighted]]
  end




  private


  def train_model(tags_train_input, height)
    table = {:data => {}, :results => {}}
    tags_train_input.each do |index, tag|
      table[:data][tag.position] = tag_answers_hash(tag)
    end
    table
  end



  def model_run_method(table, setup, tag)
    tag_vector = tag_answers_hash(tag)
    weights = {}
    table[:data].each do |table_tag, table_vector_with_empties|
      probability = @optimization.compare_vectors(tag_vector, table_vector_with_empties, weights, double_sigma_power)
      table[:results][table_tag] = probability

      #if @use_antennae_matrix
      #  coefficient_by_mi = antennae_matrix_by_mi[@reader_power][@metric_name][antenna]
      #  coefficient_by_algorithm = antennae_matrix_by_algorithm[antenna]
      #  probability *= coefficient_by_mi if antennae_matrix_by_mi.present?
      #  probability *= coefficient_by_algorithm if antennae_matrix_by_algorithm.present?
      #end
    end

    estimate = make_estimate(table[:results])
    remove_bias(tag, setup, estimate)
  end




  def make_estimate(table_results)
    nearest_neighbours = table_results.sort_by{|k,v|v}
    nearest_neighbours.reverse! if @optimization.reverse_decision_function?
    k_nearest_neighbours = nearest_neighbours[0...@k]

    points_to_center, weights = @optimization.weight_points(k_nearest_neighbours)
    weights = [] unless @weighted

    Point.center_of_points(points_to_center, weights)
  end






  def double_sigma_power
    return 50 if @metric_name == :rss
    return 2 if @metric_name == :rr
    nil
  end
end