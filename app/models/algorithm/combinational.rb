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
      tag.estimate = make_estimate tag_code
      tag.error = Point.distance(tag.estimate, tag.position)
    end
  end

  def make_estimate(tag_code)
    estimates = []
    @algorithms.each do |algorithm|
      estimates.push algorithm[tag_code][:estimate]
    end
    Point.center_of_points(estimates, @weights)
  end
end