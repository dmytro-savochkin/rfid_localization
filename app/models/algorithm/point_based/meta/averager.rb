class Algorithm::PointBased::Meta::Averager < Algorithm::PointBased

  attr_reader :algorithms

  def initialize(algorithms, tags_input)
    @algorithms = algorithms
    @tags_input = tags_input
  end


  def set_settings(averaging_type, weights = [])
    @averaging_type = averaging_type
    @weights = weights
    self
  end









  private

  def train_model(train_data, heights)
  end

  def set_up_model(model, setup_data)
  end


  def execute_tags_estimates_search(model, setup, test_data, height_index)
    calc_tags_estimates(@algorithms, test_data, height_index)
  end


  def calc_tags_estimates(algorithms, tags_input, height_index)
    tags_estimates = {}

    tags_input.each do |tag_index, tag|
      estimate = make_estimate(tag, height_index)
      tag_output = TagOutput.new(tag, estimate)
      tags_estimates[tag_index] = tag_output
    end

    #puts tags_estimates.to_yaml

    tags_estimates
  end





  def make_estimate(tag, height_index)
    tag_index = tag.id.to_s

    all_points = []
    hash = {}

    @algorithms.each_with_index do |(algorithm_name, algorithm), i|
      if algorithm.map[height_index][tag_index].present?
        answers_count = algorithm.map[height_index][tag_index][:answers_count]

        point = algorithm.map[height_index][tag_index][:estimate].to_s
        hash[point] ||= {:point => 0, :weight => 0.0}
        hash[point][:point] += 1

        all_points.push algorithm.map[height_index][tag_index][:estimate]

        if @weights.present?
          if @weights[i][answers_count.to_s].present?
            weight = @weights[i][answers_count.to_s]
          elsif @weights[i][:other].present?
            weight = @weights[i][:other]
          else
            weight = 0.0
          end
          hash[point][:weight] += weight
        end
      end
    end

    #return nil if points_hash.empty?
    #puts train_height.to_s + ' - ' + test_height.to_s + ' ' + tag.id.to_s + ': ' + weights.to_s

    #puts all_points.to_s


    points = all_points
    points = hash.keys.map{|point_string| Point.from_s(point_string)} if @averaging_type == :equal

    weights = []
    weights = hash.values.map{|h| h[:weight]} if @weights.present?

    Point.center_of_points(points, weights)
  end
end