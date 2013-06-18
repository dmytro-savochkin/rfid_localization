class Algorithm::Combinational < Algorithm::Base
  def set_settings(algorithms, weights = [])
    @algorithms = algorithms
    @weights = weights
    self
  end


  private

  def calculate_tags_output()
    tags_estimates = {}

    TagInput.tag_ids.each do |tag_index|
      tag = @tags[tag_index]

      tag_estimate = make_estimate(tag_index)
      tag_output = TagOutput.new(tag, tag_estimate)
      tags_estimates[tag_index] = tag_output
    end

    tags_estimates
  end

  def make_estimate(tag_index)
    antennae_count_tag_answered_to = @tags[tag_index].answers_count

    points = []
    weights = []
    @algorithms.each_with_index do |algorithm, index|
      unless algorithm[tag_index].nil?
        points.push algorithm[tag_index][:estimate]
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