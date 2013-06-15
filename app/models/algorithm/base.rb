class Algorithm::Base
  attr_reader :cdf, :histogram, :map, :mean_error, :std_dev, :max_error, :min_error, :show_in_chart, :tags
  attr_accessor :best_suited_for



  def initialize(input, algorithm_name, show_in_chart = {:main => true, :histogram => true})
    @algorithm_name = algorithm_name
    @work_zone = input[:work_zone]
    @tags = input[:tags]
    @show_in_chart = show_in_chart
  end


  def set_settings()
  end

  def output()
    calc_errors_for_tags

    tags_errors = @tags.values.select{|tag| tag unless tag.error[@algorithm_name].nil?}.map{|tag| tag.error[@algorithm_name]}

    calc_errors_parameters tags_errors

    @cdf = create_cdf tags_errors
    @histogram = create_histogram tags_errors

    @map = {}
    @tags.each do |tag_id, tag|
      unless tag.estimate[@algorithm_name].nil?
        @map[tag_id] = {
            :position => tag.position,
            :estimate => tag.estimate[@algorithm_name],
            :error => tag.error[@algorithm_name],
            :answers_count => tag.answers_count,
        }
      end
    end

    @best_suited_for = create_best_suited_hash

    self
  end


  private

  def calc_errors_parameters(errors)
    errors = errors.reject(&:nil?)

    @max_error = errors.max.round(1)
    @min_error = errors.min.round(1)

    @mean_error = errors.inject(0.0){|sum, el| sum + el} / errors.size
    @std_dev = Math.sqrt(errors.inject(0.0){|sum, el| sum + ((el - @mean_error) ** 2)} / (errors.size - 1))

    @mean_error = @mean_error.round(1)
    @std_dev = @std_dev.round(1)

    puts @algorithm_name
    puts errors.to_yaml
    puts @mean_error.to_yaml
    puts @std_dev.to_yaml
    puts ''
  end

  def max_error_value
    1000
  end

  def create_best_suited_hash
    hash = {:all => {:percent => 0.0, :total => Tag.tag_ids.size}}
    (1..16).each {|antennae_count| hash[antennae_count] = {:percent => 0.0, :total => nil}}
    hash
  end

  def create_cdf(data)
    size = data.size
    cdf = []
    cdf.push [data.min, 0]
    data.sort[1...data.size].each_with_index do |error, i|
      cdf.push [error, (i+1).to_f/size] if error > data.min
    end
    cdf.push [data.max + max_error_value, 1]
    cdf
  end

  def create_histogram(data)
    step = 5

    histogram = []
    (0..data.max).step(step) do |from|
      to = from + step
      histogram.push [from, data.select{|e| from <= e and e < to }.count]
    end
    histogram
  end
end