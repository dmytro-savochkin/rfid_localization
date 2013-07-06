class AntennaeCoefficientsFinder

  def initialize(measurement_information, algorithms)
    @measurement_information = measurement_information
    @algorithms = algorithms
  end




  def coefficients_by_algorithms
    antennae_coefficients = {}
    @algorithms.reject{|n,a|a.class == Algorithm::Combinational}.each do |algorithm_name, algorithm|
      cache_name = 'antennae_coefficients_by_algorithm_' + algorithm_name
      antennae_coefficients[algorithm_name] = Rails.cache.fetch(cache_name, :expires_in => 1.day) do
        algorithm.calc_antennae_coefficients
      end
    end
    antennae_coefficients
  end




  def coefficients_by_mi
    cache_name = 'antennae_coefficients_by_mi'
    Rails.cache.fetch(cache_name, :expires_in => 1.day) do
      antennae_coefficients = {}

      height = MeasurementInformation::Base::HEIGHTS.first
      MeasurementInformation::Base::READER_POWERS.each do |reader_power|
        antennae_errors = antennae_errors(reader_power, height)
        error_coefficients = error_coefficients(antennae_errors)
        percent_coefficients = percent_coefficients(error_coefficients)
        antennae_coefficients[reader_power] = normalized_coefficients(percent_coefficients)
      end

      antennae_coefficients
    end
  end












  private

  def antennae_errors(reader_power, height)
    errors = {}

    1.upto(16) do |antenna|
      errors[antenna] ||= {}

      TagInput.tag_ids.each do |tag_index|
        tag = TagInput.new(tag_index)
        answers = @measurement_information[reader_power][height][:tags][tag_index].answers

        answer_exists = (answers[:a][:average][antenna] == 1)
        if answer_exists
          errors[antenna][tag_index] =
              positioning_errors_for_antenna(answers, reader_power, antenna, tag)
        end
      end
    end

    errors
  end


  def positioning_errors_for_antenna(answers, reader_power, antenna_number, tag)
    antenna = Antenna.new(antenna_number, Zone::POWERS_TO_SIZES[reader_power])
    angle = tag.position.angle_to_point(antenna.coordinates)
    ac = antenna.coordinates
    antenna_to_tag_distance = Math.sqrt((ac.x - tag.position.x)**2 + (ac.y - tag.position.y)**2)

    errors = {}


    rss = answers[:rss][:average][antenna_number]
    distance_by_rss = MeasurementInformation::Rss.to_distance(rss, angle)
    errors[:rss] = (distance_by_rss - antenna_to_tag_distance) ** 2

    rr = answers[:rr][:average][antenna_number]
    distance_by_rr = MeasurementInformation::Rr.to_distance(rr, angle)
    errors[:rr] = (distance_by_rr - antenna_to_tag_distance) ** 2

    tag_signal_detected = answers[:a][:average][antenna_number]
    tag_within_antenna_zone = MeasurementInformation::A.point_in_ellipse?(tag.position, antenna)
    false_alarm = tag_signal_detected && !tag_within_antenna_zone
    signal_missing = !tag_signal_detected && tag_within_antenna_zone
    if false_alarm
      errors[:a] = 1.0
    elsif signal_missing
      errors[:a] = 0.5
    else
      errors[:a] = 0.0
    end

    errors
  end




  def error_coefficients(errors)
    coefficients = create_mi_types_hash
    1.upto(16) do |antenna|
      errors_count = errors[antenna].length
      mi_types.each do |mi_type|
        coefficients[mi_type][antenna] =
          errors[antenna].map{|tag,answer|answer[mi_type]}.inject(&:+) / errors_count
      end
    end
    coefficients
  end

  def percent_coefficients(error_coefficients)
    total_error = {}

    mi_types.each do |mi_type|
      total_error[mi_type] = error_coefficients[mi_type].values.inject(&:+)
    end

    coefficients = create_mi_types_hash
    1.upto(16) do |antenna|
      mi_types.each do |mi_type|
        coefficients[mi_type][antenna] = 1 - (error_coefficients[mi_type][antenna] / total_error[mi_type])
      end
    end

    coefficients
  end

  def normalized_coefficients(percent_coefficients)
    normalized_coefficients = create_mi_types_hash

    max = {}
    mi_types.each do |mi_type|
      max[mi_type] = percent_coefficients[mi_type].values.max
    end

    1.upto(16) do |antenna|
      mi_types.each do |mi_type|
        normalized_coefficients[mi_type][antenna] = percent_coefficients[mi_type][antenna] / max[mi_type]
      end
    end

    normalized_coefficients
  end




  def mi_types
    [:rss, :rr, :a]
  end
  def create_mi_types_hash
    {:rss => {}, :rr => {}, :a => {}}
  end



end