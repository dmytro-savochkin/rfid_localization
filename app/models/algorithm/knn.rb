class Algorithm::Knn < Algorithm::Base
  def set_settings(metric = :rss, k = 6, weighted = true, tags_for_table = {})
    @k = k
    @weighted = weighted
    @metric = metric
    @tags_for_table = tags_for_table
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


  def calc_errors_for_tags()
    @tags.each do |tag_index, data|
      table = create_table(tag_index)

      tag = @tags[tag_index]
      tag_data = fill_empty_antennae tag.answers[@metric][:average]


      table[:data].each do |table_tag, table_vector|
        p = 1.0
        tag_data.each do |antenna, datum|
          p *= gaussian(datum, table_vector[antenna])
        end
        table[:results][table_tag] = p
      end


      tag.estimate[@algorithm_name] = make_estimate table[:results]
      tag.error[@algorithm_name] = Point.distance(tag.estimate[@algorithm_name], tag.position)
    end
  end


  def make_estimate(table_results)
    weights = []
    points_to_center = []

    k_nearest_neighbours = table_results.sort_by{|k,v|v}.reverse[0...@k]
    total_probability = k_nearest_neighbours.inject(0.0) {|sum,e| sum + e.last}

    k_nearest_neighbours.each do |nearest_neighbour|
      point = nearest_neighbour.first
      probability = nearest_neighbour.last
      points_to_center.push point
      weights.push(probability / total_probability) if @weighted
    end

    Point.center_of_points(points_to_center, weights)
  end


  def gaussian(value1, value2)
    Math.exp( -((value1 - value2) ** 2) / double_sigma_power )
  end


  def create_table(tag_index)
    if @tags_for_table.empty?
      tags = @tags.except(tag_index)
    else
      tags = @tags_for_table
    end

    table = {:data => {}, :results => {}}
    tags.each do |index, tag|
      table[:data][tag.position] = fill_empty_antennae tag.answers[@metric][:average]
    end
    table
  end


  def fill_empty_antennae(hash)
    (1).upto(16) {|n| hash[n] = default_table_value unless hash.keys.include? n }
    hash
  end


  def double_sigma_power
    return 50 if @metric == :rss
    return 0.5 if @metric == :rr
    nil
  end

  def default_table_value
    return -75 if @metric == :rss
    return 0.0 if @metric == :rr
    nil
  end
end