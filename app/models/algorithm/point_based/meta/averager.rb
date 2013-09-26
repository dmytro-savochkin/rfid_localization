class Algorithm::PointBased::Meta::Averager < Algorithm::PointBased

  def initialize(algorithms, all_heights_combinations = true)
    @algorithms = algorithms
    @heights_combinations = all_heights_combinations

    #@work_zone = input[:work_zone]
    #@reader_power = input[:reader_power]
    #@tags_input = train_data
    #@all_heights_combinations = all_heights_combinations
  end


  def set_settings(averaging_type, weights = [])
    @averaging_type = averaging_type
    @weights = weights
    self
  end


  private






  def create_models_object(train_heights)
    []
  end

  def execute_tags_estimates_search(models, train_height,  test_height)
    calc_tags_estimates(@algorithms, train_height, test_height)
  end


  def calc_tags_estimates(algorithms, train_height, test_height)
    tags_estimates = {}

    TagInput.tag_ids.each do |tag_index|
      tag = TagInput.new(tag_index)
      estimate = make_estimate(tag, train_height, test_height)
      tag_output = TagOutput.new(tag, estimate)
      tags_estimates[tag_index] = tag_output
    end

    tags_estimates
  end





  def make_estimate(tag, train_height, test_height)
    tag_index = tag.id.to_s

    all_points = []
    hash = {}

    @algorithms.each_with_index do |(algorithm_name, algorithm), i|
      if algorithm.map[train_height][test_height][tag_index].present?
        answers_count = algorithm.map[train_height][test_height][tag_index][:answers_count]

        point = algorithm.map[train_height][test_height][tag_index][:estimate].to_s
        hash[point] ||= {:point => 0, :weight => 0.0}
        hash[point][:point] += 1


        all_points.push algorithm.map[train_height][test_height][tag_index][:estimate]

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



    points = all_points
    points = hash.keys.map{|point_string| Point.from_s(point_string)} if @averaging_type == :equal

    weights = []
    weights = hash.values.map{|h| h[:weight]} if @weights.present?

    Point.center_of_points(points, weights)
  end
end