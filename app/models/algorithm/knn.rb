class Algorithm::Knn < Algorithm::Base
  def set_settings(optimization_class, metric_name = :rss, k = 6, weighted = true, tags_for_table = {})
    @k = k
    @weighted = weighted
    @metric_name = metric_name
    @tags_for_table = tags_for_table
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


  def calculate_tags_output(tags = @tags)
    tags_estimates = {}

    antennae_matrix_by_mi = Rails.cache.read('antennae_coefficients_by_mi')
    antennae_matrix_by_algorithm = Rails.cache.read('antennae_coefficients_by_algorithm_wknn_ls_'+@metric_name.to_s)



    tags.each do |tag_index, tag|
      data_table = create_data_table(tag_index)

      tag_data = tag.answers[@metric_name][:average]

      data_table[:data].each do |table_tag, table_vector|
        probability = @optimization.default_value_for_decision_function

        1.upto(16).each do |antenna|
          datum = tag_data[antenna] || default_table_value
          table_datum = table_vector[antenna] || default_table_value
          g = @optimization.criterion_function(datum, table_datum, double_sigma_power)
          probability = probability.send(@optimization.method_for_adding, g)
          #if @use_antennae_matrix
          #  coefficient_by_mi = antennae_matrix_by_mi[@reader_power][@metric_name][antenna]
          #  coefficient_by_algorithm = antennae_matrix_by_algorithm[antenna]
          #  probability *= coefficient_by_mi if antennae_matrix_by_mi.present?
          #  probability *= coefficient_by_algorithm if antennae_matrix_by_algorithm.present?
          #end
        end

        data_table[:results][table_tag] = probability
      end

      tag_estimate = make_estimate(data_table[:results])
      tag_output = TagOutput.new(tag, tag_estimate)
      tags_estimates[tag_index] = tag_output
    end

    tags_estimates
  end


  def make_estimate(table_results)
    weights = []
    points_to_center = []

    nearest_neighbours = table_results.sort_by{|k,v|v}
    nearest_neighbours.reverse! if @optimization.reverse_decision_function?
    k_nearest_neighbours = nearest_neighbours[0...@k]

    total_probability = k_nearest_neighbours.inject(0.0) {|sum,e| sum + e.last}

    k_nearest_neighbours.each do |nearest_neighbour|
      point, probability = *nearest_neighbour
      points_to_center.push point
      weights.push(probability / total_probability) if @weighted
    end

    Point.center_of_points(points_to_center, weights)
  end


  def gaussian(value1, value2)
    Math.exp( -((value1 - value2) ** 2) / double_sigma_power )
  end




  def create_data_table(current_tag_index)
    if @tags_for_table.empty?
      tags = @tags.except(current_tag_index)
    else
      tags = @tags_for_table
    end

    table = {:data => {}, :results => {}}
    tags.each do |index, tag|
      table[:data][tag.position] = tag.answers[@metric_name][:average]
    end

    table
  end


  def double_sigma_power
    return 50 if @metric_name == :rss
    return 2 if @metric_name == :rr
    nil
  end

  def default_table_value
    return -75 if @metric_name == :rss
    return 0.0 if @metric_name == :rr
    nil
  end
end