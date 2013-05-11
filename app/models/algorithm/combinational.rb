class Algorithm::Combinational < Algorithm::Base
  def set_settings(algorithms, weights = [])
    @algorithms = algorithms
    @weights = weights
    self
  end

  private

  def calc_errors_for_tags
    Tag.tag_ids.each do |tag_code|
      tag = @tags[tag_code]
      tag.estimate[@algorithm_name] = make_estimate tag_code
      tag.error[@algorithm_name] = Point.distance(tag.estimate[@algorithm_name], tag.position)
    end
  end

  def make_estimate(tag_code)
    antennae_count_tag_answered_to = @tags[tag_code].answers_count

    points = []
    weights = []
    @algorithms.each_with_index do |algorithm, index|
      unless algorithm[tag_code].nil?
        points.push algorithm[tag_code][:estimate]
        unless @weights.empty? or @weights[antennae_count_tag_answered_to].nil?
          weights.push @weights[antennae_count_tag_answered_to][index]
        end
      end
    end
    return nil if points.empty?

    unless weights.empty?
      weights_sum = weights.inject(&:+)
      weights = weights.map{|e| e / weights_sum} if weights_sum != 1.0
    end

    Point.center_of_points(points, weights)
  end
end