class Algorithm::Combinational < Algorithm::Base
  def set_settings(algorithms, weights = [])
    @algorithms = algorithms
    @weights = weights
    self
  end

  private

  def calc_errors_for_tags
    @tags.each_with_index do |(tag_code, data), tag_index|
      tag = @tags[tag_code]
      tag.estimate = make_estimate tag_index
      tag.error = Point.distance(tag.estimate, tag.position)
    end
  end

  def make_estimate(tag_index)
    estimates = @algorithms.map do |estimate|
      Point.new(estimate[1][tag_index][0], estimate[1][tag_index][1])
    end
    Point.center_of_points(estimates, @weights)
  end
end