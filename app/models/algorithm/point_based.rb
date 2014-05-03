class Algorithm::PointBased < Algorithm::Base

  attr_reader :cdf, :pdf, :map, :errors_parameters, :errors, :group
  attr_accessor :best_suited


  def initialize(reader_power, manager_id, group, train_data, model_must_be_retrained, apply_means_unbiasing)
    super(reader_power, manager_id, train_data, model_must_be_retrained)
    @apply_means_unbiasing = apply_means_unbiasing
    @group = group
  end


  private



  def specific_output(model, test_data, index)
    @cdf ||= {}
    @pdf ||= {}
    @errors_parameters ||= {}
    @errors ||= {}
    @best_suited ||= {}

    output = calc_tags_estimates(model, @setup, test_data, index)

    @errors[index] = output.values.reject{|tag|tag.error.nil?}.map{|tag| tag.error}.sort

    @map[index] = {}
    test_data.each do |tag_index, tag|
      if output[tag_index] != nil and tag != nil
        @map[index][tag_index] = {
            :position => tag.position,
            :zone => Zone.new(tag.zone).coordinates,
            :answers_count => tag.answers_count,
            :estimate => output[tag_index].estimate,
            :error => output[tag_index].error
        }
      end
    end

    @cdf[index] = create_cdf(@errors[index])
    @pdf[index] = create_pdf(@errors[index])

    @errors_parameters[index] = calc_localization_parameters(output, test_data, @errors[index])

    @best_suited[index] = create_best_suited_hash
  end






  def calc_tags_estimates(model, setup, input_tags, height_index)
    tags_estimates = {}

    input_tags.each do |tag_index, tag|
      estimate = model_run_method(model, setup[height_index], tag)
      unless estimate.zero?
        tag_output = TagOutput.new(tag, estimate)
        tags_estimates[tag_index] = tag_output
      end
    end

    tags_estimates
  end






  def set_up_model(model, train_data, setup_data, height_index)
    return nil if setup_data.nil?

    estimate_errors = {}

    estimates = {}
    setup_data.each do |tag_index, tag|
      estimate = model_run_method(model, nil, tag)
      estimates[tag_index] = estimate
      #error = Point.distance(tag.position, estimate)
      estimate_errors[tag.answers_count] ||= {:x => [], :y => [], :total => []}
      estimate_errors[:all] ||= {:x => [], :y => [], :total => []}

      estimate_errors[tag.answers_count][:x].push( tag.position.x - estimate.x )
      estimate_errors[tag.answers_count][:y].push( tag.position.y - estimate.y )
      estimate_errors[tag.answers_count][:total].push( Point.distance(tag.position, estimate) )
      estimate_errors[:all][:x].push( tag.position.x - estimate.x )
      estimate_errors[:all][:y].push( tag.position.y - estimate.y )
      estimate_errors[:all][:total].push( Point.distance(tag.position, estimate) )
    end

    means = {}
    stddevs = {}
    lengths = {}
    estimate_errors.each do |antennae_count, errors_for_current_antennae_count|
      lengths[antennae_count] = errors_for_current_antennae_count[:x].length
      means[antennae_count] = {
          :x => errors_for_current_antennae_count[:x].mean,
          :y => errors_for_current_antennae_count[:y].mean,
          :total => errors_for_current_antennae_count[:total].mean
      }
      stddevs[antennae_count] = {
          :x => errors_for_current_antennae_count[:x].stddev,
          :y => errors_for_current_antennae_count[:y].stddev,
          :total => errors_for_current_antennae_count[:total].stddev
      }
    end

    retrained_model = retrain_model(train_data, setup_data, @heights_combinations[height_index])

    {
        :stddevs => stddevs,
        :means => means,
        :lengths => lengths,
        :estimates => estimates,
        :retrained_model => retrained_model
    }
  end




  def remove_bias(tag, setup, estimate)
    if @apply_means_unbiasing
      unless setup.nil?
        if setup[:lengths][tag.answers_count].to_i > 5
          estimate.x -= setup[:means][tag.answers_count][:x]
          estimate.y -= setup[:means][tag.answers_count][:y]
        end
      end
    end
    estimate
  end





















  def calc_localization_parameters(output, input, errors)
    parameters = {
        :total => {},
        :x => {},
        :y => {},
        :by_antenna_count => {:variances => {}, :errors => {}, :lengths => {}, :means => {}}
    }
    parameters[:total][:max] = errors.max.round(1)
    parameters[:total][:min] = errors.min.round(1)

    quantile = ->(p) do
      n = errors.length
      k = (p * (n - 1)).floor
      return errors[k + 1] if (k + 1) < p * n
      return (errors[k] + errors[k + 1]) / 2 if (k + 1) == p * n
      return errors[k] if (k + 1) > p * n
      nil
    end

    parameters[:total][:percentile10] = quantile.call(0.1)
    parameters[:total][:quartile1] = quantile.call(0.25)
    parameters[:total][:median] = quantile.call(0.5)
    parameters[:total][:quartile3] = quantile.call(0.75)
    parameters[:total][:percentile90] = quantile.call(0.9)

    parameters[:total][:before_percentile10] =
        errors.select{|error| error < (parameters[:total][:percentile10] - 1)}
    parameters[:total][:above_percentile90] =
        errors.select{|error| error > (parameters[:total][:percentile90] + 1)}

    parameters[:total][:mean] = errors.mean.round(1)
    parameters[:total][:stddev] = errors.stddev.round(1)
    parameters[:total][:rayleigh_sigma] = (errors.map{|v| v**2}.mean / 2).round(2)


    shifted_estimates = {:x => [], :y => []}
    output.each do |tag_index, tag_output|
      tag_input = input[tag_index]
      unless tag_output.estimate.nil?
        shifted_estimates[:x].push(tag_output.estimate.x - tag_input.position.x)
        shifted_estimates[:y].push(tag_output.estimate.y - tag_input.position.y)

        parameters[:by_antenna_count][:errors][tag_input.answers_count] ||= []
        parameters[:by_antenna_count][:lengths][tag_input.answers_count] ||= 0

        parameters[:by_antenna_count][:errors][tag_input.answers_count].push tag_output.error
        parameters[:by_antenna_count][:lengths][tag_input.answers_count] += 1
      end
    end

    (1..16).each do |answers_count|
      errors_for_current_answers_count = parameters[:by_antenna_count][:errors][answers_count]
      if errors_for_current_answers_count.present?
        parameters[:by_antenna_count][:variances][answers_count] =
            parameters[:by_antenna_count][:errors][answers_count].variance
        parameters[:by_antenna_count][:means][answers_count] =
            parameters[:by_antenna_count][:errors][answers_count].mean
      end
    end


    parameters[:x][:mean] = shifted_estimates[:x].mean.round(1)
    parameters[:x][:stddev] = shifted_estimates[:x].stddev.round(1)
    parameters[:y][:mean] = shifted_estimates[:y].mean.round(1)
    parameters[:y][:stddev] = shifted_estimates[:y].stddev.round(1)

    parameters
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
  def create_cdf(errors)
    cdf = []
    n = errors.size

    errors.each_with_index do |error, m|
      if m == 0
        cdf.push [0, 0]
        cdf.push [errors.min, 0]
      elsif m == n
        cdf.push [errors.max, 1]
        cdf.push [errors.max + max_error_value, 1]
      else
        cdf.push [errors[m], m.to_f / n]
        cdf.push [errors[m+1], m.to_f / n]
      end
    end

    cdf
  end

  def create_pdf(errors)
    data = errors
    step = 5

    histogram = []
    (0..data.max).step(step) do |from|
      to = from + step
      histogram.push [from, data.select{|e| from <= e and e < to }.count]
    end
    histogram
  end






  #def calc_antennae_coefficients
  #  antennae_coefficients = {}
  #  tags_input = {}
  #  tags_output = {}
  #
  #  (1..16).each do |antenna_number|
  #    antennae_coefficients[antenna_number] = []
  #    tags_input[antenna_number] = clean_tags_from_antenna(antenna_number)
  #    tags_output[antenna_number] = calc_tags_output(tags_input[antenna_number])
  #  end
  #
  #  @tags_test_input.each do |tag_index, tag|
  #    if tag.answers_count > 1
  #      total_error = tag.answers[:rss][:average].map do |antenna,answer|
  #        tags_output[antenna][tag_index].error
  #      end.inject(&:+)
  #
  #      tag.answers[:a][:average].reject{|antenna,answer| answer == 0}.each do |antenna_number, answer|
  #        percent = tags_output[antenna_number][tag_index].error / total_error
  #        antennae_coefficients[antenna_number].push(percent)
  #      end
  #    end
  #  end
  #
  #  (1..16).each do |antenna_number|
  #    antennae_coefficients[antenna_number] = antennae_coefficients[antenna_number].inject(&:+) / antennae_coefficients[antenna_number].length
  #  end
  #  max = antennae_coefficients.values.max
  #  (1..16).each do |antenna_number|
  #    antennae_coefficients[antenna_number] = antennae_coefficients[antenna_number] / max
  #  end
  #
  #  antennae_coefficients
  #end

  #def clean_tags_from_antenna(antenna_number)
  #  tags_input = {}
  #  @tags_test_input.each do |tag_index, tag|
  #    tags_input[tag_index] = TagInput.clone(tag).clean_from_antenna(antenna_number)
  #  end
  #  tags_input
  #end

end