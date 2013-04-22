class KNearestNeighbours < LocalizationAlgorithm
  attr_accessor :tags_errors, :cdf_data, :map_data

  def initialize(work_zone, input_data)
    @work_zone = work_zone
    @tags_data = input_data.values.first.values.first.values.first

    @tags_errors = []

    @tags_data.each do |tag_index, data|
      rss_table = create_rss_table(@tags_data.except(tag_index))

      tag = @tags_data[tag_index]
      tag_rss = fill_empty_antennae tag.answers[:rss][:average]


      rss_table[:data].each do |table_tag, rss_table_vector|
        p = 1.0
        tag_rss.each do |antenna, rss|
          p *= gaussian(rss, rss_table_vector[antenna])
        end
        rss_table[:results][table_tag] = p
      end

      tag.estimate = make_estimate rss_table[:results]

      @tags_errors.push Point.distance(tag.estimate, tag.position)
    end

    @cdf_data = cdf(@tags_errors)
    @map_data = @tags_data.values.map{|tag| [tag.position.to_a, tag.estimate.to_a]}
  end




  private

  def make_estimate(rss_table_results)
    weights = []
    points_to_center = []

    k_nearest_neighbours = rss_table_results.sort_by{|k,v|v}.reverse[0...k]
    total_probability = k_nearest_neighbours.inject(0.0) {|sum,e| sum + e.last}


    k_nearest_neighbours.each do |nearest_neighbour|
      point = nearest_neighbour.first
      probability = nearest_neighbour.last
      points_to_center.push point
      weights.push probability / total_probability
    end

    Point.center_of_points(points_to_center, weights)
  end


  # number of K nearest neighbours
  def k
    4
  end

  def weighted
    true
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