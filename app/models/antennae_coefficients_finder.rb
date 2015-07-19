#class AntennaeCoefficientsFinder
#
#  def initialize(measurement_information, algorithms)
#    @mi = measurement_information
#    @algorithms = algorithms
#
#    #@limits = {
#    #    :rss => 100.0,
#    #    :rr => 100.0,
#    #    :a => 0.7
#    #}
#
#  end
#
#
#
#
#  def coefficients_by_algorithms
#    antennae_coefficients = {}
#    @algorithms.reject{|n,a|a.class == Algorithm::Combinational}.each do |algorithm_name, algorithm|
#      cache_name = 'antennae_coefficients_by_algorithm_' + algorithm_name
#      antennae_coefficients[algorithm_name] = Rails.cache.fetch(cache_name, :expires_in => 1.day) do
#        algorithm.calc_antennae_coefficients
#      end
#    end
#    antennae_coefficients
#  end
#
#
#
#
#  def coefficients_by_mi
#    #cache_name = 'antennae_coefficients_by_mi'
#    #Rails.cache.fetch(cache_name, :expires_in => 1.day) do
#    antennae_coefficients = {}
#
#
#    #puts @mi[20].to_yaml
#
#    stddevs = {}
#
#    (20..24).each do |reader_power|
#      stddevs[reader_power] ||= {}
#
#      antennae_coefficients[reader_power] ||= {}
#      @mi[reader_power].each_with_index do |mi_by_height, height_number|
#        antennae_errors = antennae_errors(mi_by_height, reader_power, height_number)
#        puts antennae_errors.to_yaml
#        errors_means, errors_stddevs = errors_mean_and_stddev(antennae_errors)
#
#        stddevs[reader_power][height_number] = errors_stddevs[:rss].values
#
#        puts errors_means.to_yaml
#        puts errors_stddevs.to_yaml
#        antennae_coefficients[reader_power][height_number] = percent_coefficients(errors_stddevs)
#        antennae_coefficients[reader_power][height_number] = [errors_means, errors_stddevs]
#        puts antennae_coefficients[reader_power][height_number].to_yaml
#        puts ''
#      end
#
#
#
#      puts 'CORRELATION: ' + reader_power.to_s
#      puts calc_std_devs_correlation(stddevs, reader_power).to_yaml
#      puts ''
#
#
#    end
#
#    antennae_coefficients
#  end
#
#
#
#
#
#
#
#
#
#
#
#
#  private
#
#
#  def calc_std_devs_correlation(stddevs, reader_power)
#    correlation = {}
#    (0..3).each do |height1|
#      (0..3).each do |height2|
#        correlation[height1.to_s + '_' + height2.to_s] = Math.correlation(
#            stddevs[reader_power][height1],
#            stddevs[reader_power][height2]
#        )
#      end
#    end
#    correlation
#  end
#
#  def antennae_errors(tags_input, reader_power, height)
#    output_errors = {}
#
#    (1..16).each do |antenna|
#      output_errors[antenna] ||= {}
#
#      tags_input.each do |tag_index, tag|
#        answer_exists = (tag.answers[:a][:average][antenna] == 1)
#        if answer_exists
#          output_errors[antenna][tag_index] =
#              positioning_errors_for_antenna(tag, reader_power, height, antenna)
#        end
#      end
#    end
#
#    output_errors
#  end
#
#
#  def positioning_errors_for_antenna(tag, reader_power, height_number, antenna_number)
#    antenna = Antenna.new(antenna_number, Zone::POWERS_TO_SIZES[reader_power])
#    angle = antenna.coordinates.angle_to_point(tag.position)
#    ac = antenna.coordinates
#    antenna_to_tag_distance = Math.sqrt((ac.x - tag.position.x)**2 + (ac.y - tag.position.y)**2)
#
#    errors = {}
#
#
#
#    rss = tag.answers[:rss][:average][antenna_number]
#    distance_by_rss = MI::Rss.to_distance(rss, angle, antenna_number, :specific,
#        MI::Base::HEIGHTS[height_number], reader_power, 'powers=1__ellipse=1.5', 1.5
#    )
#    errors[:rss] = distance_by_rss - antenna_to_tag_distance
#
#
#    rr = tag.answers[:rr][:average][antenna_number]
#    distance_by_rr = MI::Rr.to_distance(rr, angle, antenna_number, :average,
#        MI::Base::HEIGHTS[height_number], reader_power, 'new_elliptical'
#    )
#    errors[:rr] = distance_by_rr - antenna_to_tag_distance
#
#
#    tag_signal_detected = tag.answers[:a][:average][antenna_number]
#    tag_within_antenna_zone = MI::A.point_in_ellipse?(tag.position, antenna)
#    false_alarm = tag_signal_detected && !tag_within_antenna_zone
#    signal_missing = !tag_signal_detected && tag_within_antenna_zone
#    if false_alarm
#      errors[:a] = 1.0
#    elsif signal_missing
#      errors[:a] = 0.5
#    else
#      errors[:a] = 0.0
#    end
#
#    errors
#  end
#
#
#
#
#  def errors_mean_and_stddev(errors)
#    means = create_mi_types_hash
#    stddevs = create_mi_types_hash
#    (1..16).each do |antenna|
#      if errors[antenna].present?
#        mi_types.each do |mi_type|
#          means[mi_type][antenna] = errors[antenna].map{|tag,answer| answer[mi_type]}.mean
#          stddevs[mi_type][antenna] = errors[antenna].map{|tag,answer| answer[mi_type]}.stddev
#        end
#      end
#    end
#    [means, stddevs]
#  end
#
#  def percent_coefficients(errors)
#    total_error = {}
#
#    mi_types.each do |mi_type|
#      total_error[mi_type] = errors[mi_type].values.sum
#    end
#
#    coefficients = create_mi_types_hash
#    (1..16).each do |antenna|
#      mi_types.each do |mi_type|
#        limit = Antenna::ERROR_LIMITS[mi_type]
#        average_error = errors[mi_type][antenna]
#        if average_error.present?
#          if average_error > limit
#            coefficients[mi_type][antenna] = 0.0
#          else
#            coefficients[mi_type][antenna] = (limit - average_error) / limit
#          end
#        end
#      end
#    end
#
#    coefficients
#  end
#
#
#
#
#  def mi_types
#    [:rss, :rr, :a]
#    [:rss]
#  end
#  def create_mi_types_hash
#    {:rss => {}, :rr => {}, :a => {}}
#    {:rss => {}}
#  end
#
#
#
#end