class Algorithm::PointBased::Knn < Algorithm::PointBased
  def set_settings(optimization_class, metric_name = :rss, k = 6, weighted = true, tags_for_table = {})
    @k = k
    @weighted = weighted
    @metric_name = metric_name
    @mi_class = MeasurementInformation::Base.class_by_mi_type(metric_name)
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


  def calc_tags_output
    tags_estimates = {}

    antennae_matrix_by_mi = Rails.cache.read('antennae_coefficients_by_mi')
    antennae_matrix_by_algorithm = Rails.cache.read('antennae_coefficients_by_algorithm_wknn_ls_'+@metric_name.to_s)



    n = 1

    Benchmark.bm(7) do |x|
      x.report('knn') do
        n.times do



          data_table = create_data_table if @tags_for_table.present?
          tags_estimates = {}

          @tags_test_input.each do |tag_index, tag|
            data_table = create_data_table(tag_index) if @tags_for_table.empty?

            tag_data = tag.answers[@metric_name][:average]

            data_table[:data].each do |table_tag, table_vector_with_empties|
              tag_vector = {}
              (1..16).each{|antenna| tag_vector[antenna] = tag_data[antenna] || @mi_class.default_value }
              probability = @optimization.compare_vectors(tag_vector, table_vector_with_empties, double_sigma_power)



              #if @use_antennae_matrix
              #  coefficient_by_mi = antennae_matrix_by_mi[@reader_power][@metric_name][antenna]
              #  coefficient_by_algorithm = antennae_matrix_by_algorithm[antenna]
              #  probability *= coefficient_by_mi if antennae_matrix_by_mi.present?
              #  probability *= coefficient_by_algorithm if antennae_matrix_by_algorithm.present?
              #end

              data_table[:results][table_tag] = probability
            end

            tag_estimate = make_estimate(data_table[:results])

            tag_output = TagOutput.new(tag, tag_estimate)
            tags_estimates[tag_index] = tag_output
          end



        end
      end
    end



    tags_estimates
  end


  def make_estimate(table_results)
    nearest_neighbours = table_results.sort_by{|k,v|v}
    nearest_neighbours.reverse! if @optimization.reverse_decision_function?
    k_nearest_neighbours = nearest_neighbours[0...@k]

    points_to_center, weights = @optimization.weight_points(k_nearest_neighbours)
    weights = [] unless @weighted

    Point.center_of_points(points_to_center, weights)
  end






  def create_data_table(current_tag_index = nil)
    if @tags_for_table.empty?
      tags = @tags_test_input.except(current_tag_index)
    else
      tags = @tags_for_table
    end

    table = {:data => {}, :results => {}}
    tags.each do |index, tag|
      table[:data][tag.position] = {}
      (1..16).map do |antenna|
        table[:data][tag.position][antenna] = tag.answers[@metric_name][:average][antenna] || @mi_class.default_value
      end
    end

    table
  end


  def double_sigma_power
    return 50 if @metric_name == :rss
    return 2 if @metric_name == :rr
    nil
  end
end