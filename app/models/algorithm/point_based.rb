class Algorithm::PointBased < Algorithm::Base

  attr_reader :tags_input, :output,
      :cdf, :pdf, :map, :errors_parameters,
      :reader_power, :work_zone, :errors,
      :heights_combinations, :setup
  attr_accessor :best_suited






  def output()
    #train_heights, setup_heights, test_heights = get_train_and_test_heights
    #models = create_models_object(train_heights.uniq)

    @setup = {}
    @output = {}
    @map = {}
    @cdf = {}
    @pdf = {}
    @errors_parameters = {}
    @errors = {}
    @best_suited = {}
    @heights_combinations = {}

    @tags_input.each_with_index do |tags_input_current_height, index|
      train_data = tags_input_current_height[:train]
      setup_data = tags_input_current_height[:setup]
      test_data = tags_input_current_height[:test]
      heights = tags_input_current_height[:heights]

      @heights_combinations[index] = heights

      model = train_model(train_data, heights[:train])

      @setup[index] = set_up_model(model, setup_data)

      @output[index] = execute_tags_estimates_search(model, @setup[index], test_data, index)

      @errors[index] =
          @output[index].values.reject{|tag|tag.error.nil?}.map{|tag| tag.error}.sort

      @map[index] = {}
      test_data.each do |tag_index, tag|
        if @output[index][tag_index] != nil and tag != nil
          @map[index][tag_index] = {
              :position => tag.position,
              :zone => Zone.new(tag.zone).coordinates,
              :answers_count => tag.answers_count,
              :estimate => @output[index][tag_index].estimate,
              :error => @output[index][tag_index].error
          }
        end
      end

      @cdf[index] = create_cdf(@errors[index])
      @pdf[index] = create_pdf(@errors[index])

      #puts @tags_input[train_height].keys.to_s
      #puts @output[train_height][test_height].keys.to_s
      @errors_parameters[index] =
          calc_localization_parameters(@output[index], test_data, @errors[index])

      @best_suited[index] = create_best_suited_hash
    end

    self
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








  private

  def execute_tags_estimates_search(model, setup, test_data, height_index)
    calc_tags_estimates(model, setup, test_data)
  end


  def set_up_model(model, setup_data)
    estimate_errors = {}

    setup_data.each do |tag_index, tag|
      estimate = model_run_method(model, nil, tag)
      #error = Point.distance(tag.position, estimate)
      estimate_errors[tag.answers_count] ||= {}
      estimate_errors[tag.answers_count][:x] ||= []
      estimate_errors[tag.answers_count][:y] ||= []
      estimate_errors[tag.answers_count][:x].push( tag.position.x - estimate.x )
      estimate_errors[tag.answers_count][:y].push( tag.position.y - estimate.y )
    end

    means = {}
    stddevs = {}
    estimate_errors.each do |antennae_count, errors_for_current_antennae_count|
      means[antennae_count] = {
          :x => errors_for_current_antennae_count[:x].mean,
          :y => errors_for_current_antennae_count[:y].mean
      }
      stddevs[antennae_count] = {
          :x => errors_for_current_antennae_count[:x].stddev,
          :y => errors_for_current_antennae_count[:y].stddev
      }
    end

    {:stddevs => stddevs, :means => means}
  end





  #def get_train_and_test_heights
  #  if @heights_combinations == :all
  #    train_heights = [3,3,2,2,0,0]
  #    setup_heights = [2,0,3,0,2,3]
  #    test_heights =  [0,2,0,3,3,2]
  #  elsif @heights_combinations == :basic
  #    train_heights = [3,3,0]
  #    setup_heights = [2,0,2]
  #    test_heights =  [0,2,3]
  #  else
  #    train_heights = [3]
  #    setup_heights = [2]
  #    test_heights =  [0]
  #  end
  #  [train_heights, setup_heights, test_heights]
  #end



  #def create_models_object(train_heights)
  #  models = {}
  #  train_heights.each do |height|
  #    model = train_model(@tags_input[height], height)
  #    models[height] = model
  #  end
  #  models
  #end

  #def clean_tags_from_antenna(antenna_number)
  #  tags_input = {}
  #  @tags_test_input.each do |tag_index, tag|
  #    tags_input[tag_index] = TagInput.clone(tag).clean_from_antenna(antenna_number)
  #  end
  #  tags_input
  #end




  def calc_tags_estimates(model, setup, input_tags)
    tags_estimates = {}

    input_tags.each do |tag_index, tag|
      estimate = model_run_method(model, setup, tag)
      unless estimate.zero?
        tag_output = TagOutput.new(tag, estimate)
        tags_estimates[tag_index] = tag_output
      end
    end

    tags_estimates
  end















  def calc_localization_parameters(output, input, errors)
    parameters = {:total => {}, :x => {}, :y => {}}
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


    shifted_estimates = {:x => [], :y => []}
    output.each do |tag_index, tag_output|
      tag_input = input[tag_index]
      #puts tag_index.to_s
      unless tag_output.estimate.nil?
        shifted_estimates[:x].push(tag_output.estimate.x - tag_input.position.x)
        shifted_estimates[:y].push(tag_output.estimate.y - tag_input.position.y)
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

end