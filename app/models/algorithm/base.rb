class Algorithm::Base
  attr_reader :cdf, :histogram, :tags_output, :map, :mean_error, :std_dev, :max_error, :min_error,
              :show_in_chart, :tags, :compare_by_antennae, :reader_power, :work_zone
  attr_accessor :best_suited_for



  def initialize(input, compare_by_antennae = true, show_in_chart = {:main => true, :histogram => true},
      use_antennae_matrix = true)
    @work_zone = input[:work_zone]
    @tags = input[:tags]
    @reader_power = input[:reader_power]
    @compare_by_antennae = compare_by_antennae
    @show_in_chart = show_in_chart
    @use_antennae_matrix = use_antennae_matrix
  end


  def set_settings() end


  def output()
    @tags_output = calculate_tags_output
    errors = @tags_output.values.map{|tag| tag.error}

    calc_errors_parameters errors

    @cdf = create_cdf errors
    @histogram = create_histogram errors

    @map = {}
    @tags.each do |tag_index, tag|
      unless @tags_output[tag_index].nil?
        @map[tag_index] = {
            :position => tag.position,
            :estimate => @tags_output[tag_index].estimate,
            :error => @tags_output[tag_index].error,
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
      tags_output[antenna_number] = calculate_tags_output(tags_input[antenna_number])
    end

    @tags.each do |tag_index, tag|
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
    @tags.each do |tag_index, tag|
      tags_input[tag_index] = TagInput.clone(tag).clean_from_antenna(antenna_number)
    end
    tags_input
  end

  def calc_errors_parameters(errors)
    errors = errors.reject(&:nil?)

    @max_error = errors.max.round(1)
    @min_error = errors.min.round(1)

    @mean_error = errors.inject(0.0){|sum, el| sum + el} / errors.size
    @std_dev = Math.sqrt(errors.inject(0.0){|sum, el| sum + ((el - @mean_error) ** 2)} / (errors.size - 1))

    @mean_error = @mean_error.round(1)
    @std_dev = @std_dev.round(1)
  end

  def max_error_value
    1000
  end

  def create_best_suited_hash
    hash = {:all => 0}
    (1..16).each {|antennae_count| hash[antennae_count] = 0}
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