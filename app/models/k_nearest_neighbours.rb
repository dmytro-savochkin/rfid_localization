class KNearestNeighbours < LocalizationAlgorithm
  attr_accessor :k_graph

  def set_settings(k = 6, weighted = 1)
    @k = k
    @weighted = weighted
    self
  end

  def make_k_graph(k_values = (1..1))
    @k_graph = [[], []]
    ([0, 1]).each do |weighted|
      k_values.each do |k|
        knn = KNearestNeighbours.new.set_settings(k, weighted).output
        @k_graph[weighted].push([k, knn.average_error])
      end
    end
    @k_graph = @k_graph.to_json
  end


  private


  def calc_errors_for_tags()
    @tags.each do |tag_index, data|
      rss_table = create_rss_table(@tags.except(tag_index))

      tag = @tags[tag_index]
      tag_rss = fill_empty_antennae tag.answers[:rss][:average]


      rss_table[:data].each do |table_tag, rss_table_vector|
        p = 1.0
        tag_rss.each do |antenna, rss|
          p *= gaussian(rss, rss_table_vector[antenna])
        end
        rss_table[:results][table_tag] = p
      end


      tag.estimate = make_estimate rss_table[:results]
      tag.error = Point.distance(tag.estimate, tag.position)
    end
  end


  def make_estimate(rss_table_results)
    weights = []
    points_to_center = []

    k_nearest_neighbours = rss_table_results.sort_by{|k,v|v}.reverse[0...@k]
    total_probability = k_nearest_neighbours.inject(0.0) {|sum,e| sum + e.last}

    k_nearest_neighbours.each do |nearest_neighbour|
      point = nearest_neighbour.first
      probability = nearest_neighbour.last
      points_to_center.push point
      weights.push probability / total_probability if @weighted == 1
    end

    Point.center_of_points(points_to_center, weights)
  end


  def gaussian(rss1, rss2)
    sigma_power = 50
    Math.exp(-((rss1-rss2)**2)/(sigma_power))
  end


  def create_rss_table(tags)
    rss_table = {:data => {}, :results => {}}
    tags.each do |index, tag|
      rss_table[:data][tag.position] = fill_empty_antennae tag.answers[:rss][:average]
    end
    rss_table
  end


  def fill_empty_antennae(hash)
    (1).upto(16) {|n| hash[n] = -75 unless hash.keys.include? n }
    hash
  end
end