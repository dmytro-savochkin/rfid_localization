class Algorithm::PointBased < Algorithm::Base

  def output()

    @tags_test_output = calc_tags_output
    @errors = @tags_test_output.values.reject{|tag|tag.error.nil?}.map{|tag| tag.error}.sort

    @cdf = create_cdf

    calc_estimate_parameters
    calc_errors_parameters

    @histogram = create_histogram

    @map = {}
    TagInput.tag_ids.each do |index|
      tag = @tags_test_input[index]
      if @tags_test_output[index] != nil and tag != nil
        @map[index] = {
            :position => tag.position,
            :test_estimate => @tags_test_output[index].estimate,
            :error => @tags_test_output[index].error,
            :answers_count => tag.answers_count,
        }
      end
    end

    @best_suited_for = create_best_suited_hash

    self
  end





  def calc_antennae_coefficients
    antennae_coefficients = {}
    tags_input = {}
    tags_output = {}

    (1..16).each do |antenna_number|
      antennae_coefficients[antenna_number] = []
      tags_input[antenna_number] = clean_tags_from_antenna(antenna_number)
      tags_output[antenna_number] = calc_tags_output(tags_input[antenna_number])
    end

    @tags_test_input.each do |tag_index, tag|
      if tag.answers_count > 1
        total_error = tag.answers[:rss][:average].map do |antenna,answer|
          tags_output[antenna][tag_index].error
        end.inject(&:+)

        tag.answers[:a][:average].reject{|antenna,answer| answer == 0}.each do |antenna_number, answer|
          percent = tags_output[antenna_number][tag_index].error / total_error
          antennae_coefficients[antenna_number].push(percent)
        end
      end
    end

    (1..16).each do |antenna_number|
      antennae_coefficients[antenna_number] = antennae_coefficients[antenna_number].inject(&:+) / antennae_coefficients[antenna_number].length
    end
    max = antennae_coefficients.values.max
    (1..16).each do |antenna_number|
      antennae_coefficients[antenna_number] = antennae_coefficients[antenna_number] / max
    end

    antennae_coefficients
  end








  private


  def clean_tags_from_antenna(antenna_number)
    tags_input = {}
    @tags_test_input.each do |tag_index, tag|
      tags_input[tag_index] = TagInput.clone(tag).clean_from_antenna(antenna_number)
    end
    tags_input
  end



  def calc_estimate_parameters()
    @estimates_parameters = {:x => {}, :y => {}}

    shifted_estimates = {:x => [], :y => []}

    @tags_test_output.each do |tag_name, tag_output|
      tag_input = @tags_test_input[tag_name]
      unless tag_output.estimate.nil?
        shifted_estimates[:x].push(tag_output.estimate.x - tag_input.position.x)
        shifted_estimates[:y].push(tag_output.estimate.y - tag_input.position.y)
      end
    end

    @estimates_parameters[:x][:mean] = shifted_estimates[:x].mean.round(1)
    @estimates_parameters[:x][:stddev] = shifted_estimates[:x].stddev.round(1)
    @estimates_parameters[:y][:mean] = shifted_estimates[:y].mean.round(1)
    @estimates_parameters[:y][:stddev] = shifted_estimates[:y].stddev.round(1)
  end


  def calc_errors_parameters
    errors = @errors.reject(&:nil?).sort
    @errors_parameters = {}

    @errors_parameters[:max] = errors.max.round(1)
    @errors_parameters[:min] = errors.min.round(1)

    quantile = ->(p) do
      n = errors.length
      k = (p * (n - 1)).floor
      return errors[k + 1] if (k + 1) < p * n
      return (errors[k] + errors[k + 1]) / 2 if (k + 1) == p * n
      return errors[k] if (k + 1) > p * n
      nil
    end

    @errors_parameters[:percentile10] = quantile.call(0.1)
    @errors_parameters[:quartile1] = quantile.call(0.25)
    @errors_parameters[:median] = quantile.call(0.5)
    @errors_parameters[:quartile3] = quantile.call(0.75)
    @errors_parameters[:percentile90] = quantile.call(0.9)

    @errors_parameters[:before_percentile10] = errors.select{|error| error < (@errors_parameters[:percentile10] - 1)}
    @errors_parameters[:above_percentile90] = errors.select{|error| error > (@errors_parameters[:percentile90] + 1)}


    @errors_parameters[:mean] = errors.mean.round(1)
    @errors_parameters[:stddev] = errors.stddev.round(1)
  end

  def max_error_value
    1000
  end

  def create_best_suited_hash
    hash = {:all => 0}
    (1..16).each {|antennae_count| hash[antennae_count] = 0}
    hash
  end



  # http://e-science.ru/math/FAQ/Statistic/Basic.html#b1415
  def create_cdf
    cdf = []
    n = @errors.size

    @errors.each_with_index do |error, m|
      if m == 0
        cdf.push [0, 0]
        cdf.push [@errors.min, 0]
      elsif m == n
        cdf.push [@errors.max, 1]
        cdf.push [@errors.max + max_error_value, 1]
      else
        cdf.push [@errors[m], m.to_f / n]
        cdf.push [@errors[m+1], m.to_f / n]
      end
    end

    cdf
  end

  def create_histogram
    data = @errors
    step = 5

    histogram = []
    (0..data.max).step(step) do |from|
      to = from + step
      histogram.push [from, data.select{|e| from <= e and e < to }.count]
    end
    histogram
  end

end